# -*- encoding: utf-8 -*-
require 'em-http'
require File.expand_path('./test_setting', File.dirname(__FILE__))

class TestEmHttpRequest < OdrkHTTPClientTestCase
  def request(&block)
    req = nil
    EM.run do
      req = yield
      req.callback do
        EM.stop
      end
      req.errback { flunk(req.error) }
    end
    req
  end

  def test_ssl
    setup_sslserver
    ssl_url = "https://#{$host}:#{$ssl_port}/"
    EM.run do
      req = EventMachine::HttpRequest.new(ssl_url + 'hello').get
      req.callback do
        assert(false, 'SSL should fail')
        EM.stop
      end
      req.errback do
        assert(true)
        EM.stop
      end
    end
  end

  def test_ssl_ca
    # The parameter :cert_chain_file of EventMachine is the certificate chain sent to the server, which is not related to verification. SSL client of EventMachine does not support SSL verification (just fail for :verify_peer => true)
    flunk('SSL configuration not supported')
  end

  def test_ssl_hostname
    setup_sslserver
    ssl_url = "https://127.0.0.1:#{$ssl_port}/"
    EM.run do
      opt = {:tls => {:verify_peer => true}}
      req = EventMachine::HttpRequest.new(ssl_url + 'hello', opt).get
      req.callback do
        assert(false, 'SSL should fail')
        EM.stop
      end
      req.errback do
        assert(true)
        EM.stop
      end
    end
  end

  def test_gzip_get
    req = request {
      EventMachine::HttpRequest.new(@url + 'compressed?enc=gzip').get(:head => { 'accept-encoding' => 'gzip' })
    }
    assert_equal('hello', req.response)
    #
    req = request {
      EventMachine::HttpRequest.new(@url + 'compressed?enc=deflate').get(:head => { 'accept-encoding' => 'deflate' })
    }
    assert_equal('hello', req.response)
  end

  def test_gzip_post
    req = request {
      EventMachine::HttpRequest.new(@url + 'compressed').post(:body => { :enc => 'gzip' }, :head => { 'accept-encoding' => 'gzip' })
    }
    assert_equal('hello', req.response)
    #
    req = request {
      EventMachine::HttpRequest.new(@url + 'compressed').post(:body => { :enc => 'deflate' }, :head => { 'accept-encoding' => 'deflate' })
    }
    assert_equal('hello', req.response)
  end

  def test_put
    req = request {
      EventMachine::HttpRequest.new(@url + 'servlet').put(:body => '')
    }
    assert_equal('put', req.response)
    #
    req = request {
      EventMachine::HttpRequest.new(@url + 'servlet').put(:body => { 1 => 2, 3 => 4 })
    }
    assert_equal('1=2&3=4', req.response_header["X_QUERY"])
    #
    req = request {
      EventMachine::HttpRequest.new(@url + 'servlet').put(:body => { 'txt' => 'あいうえお' })
    }
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', req.response_header["X_QUERY"])
    assert_equal('15', req.response_header["X_SIZE"])
  end

  def test_delete
    req = request {
      EventMachine::HttpRequest.new(@url + 'servlet').delete
    }
    assert_equal("delete", req.response)
  end

  def test_custom_method
    req = request {
      EventMachine::HttpRequest.new(@url + 'servlet?1=2&3=4').setup_request('custom', :body => 'custom?')
    }
    assert_equal('custom?', req.response)
    assert_equal('1=2&3=4', req.response_header["X_QUERY"])
  end

  def test_cookies
    flunk('cookie is not supported')
  end

  def test_post_multipart
    # !! How can I run this? https://gist.github.com/778639
    # Where're the definitions for MultipartBody, Part and Multipart?
    File.open(__FILE__) do |file|
      req = request {
        EventMachine::HttpRequest.new(@url + 'servlet').post(:body => file)
      }
      assert_match(/FIND_TAG_IN_THIS_FILE/, req.response)
    end
  end

  def test_basic_auth
    req = request {
      EventMachine::HttpRequest.new(@url + 'basic_auth').get(:head => {:authorization => ['admin', 'admin']})
    }
    assert_equal('basic_auth OK', req.response)
  end

  def test_digest_auth
    flunk 'digest auth not supported'
  end

  def test_redirect
    req = request {
      EventMachine::HttpRequest.new(@url + 'redirect3').get(:redirects => 3)
    }
    assert_equal('hello', req.response)
  end

  def test_redirect_loop_detection
    req = request {
      EventMachine::HttpRequest.new(@url + 'redirect_self').get(:redirects => 3)
    }
  end

  def test_keepalive
    server = HTTPServer::KeepAliveServer.new($host)
    body = []
    EM.run do
      conn = EventMachine::HttpRequest.new(server.url)
      req1 = conn.get(:keepalive => true)
      req1.callback {
        body << req1.response
        req2 = conn.get(:keepalive => true)
        req2.callback {
          body << req2.response
          req3 = conn.get(:keepalive => true)
          req3.callback {
            body << req3.response
            req4 = conn.get(:keepalive => true)
            req4.callback {
              body << req4.response
              req5 = conn.get(:keepalive => true)
              req5.callback {
                body << req5.response
                EM.stop
              }
              req5.errback { flunk }
            }
            req4.errback { flunk }
          }
          req3.errback { flunk }
        }
        req2.errback { flunk }
      }
      req1.errback { flunk }
    end
    assert_equal(5, body.size)
    assert_equal(1, body.unique.size)
    assert_equal('12345', body[0])
    server.close
    # chunked
    server = HTTPServer::KeepAliveServer.new($host)
    flunk('TBD')
    server.close
  end

  def test_streaming_upload
    file = Tempfile.new(__FILE__)
    file << "*" * 4096 * 100
    file.close
    req = request {
      EventMachine::HttpRequest.new(@url + 'chunked').post :file => file.path
    }
    assert(req.response_header['X_COUNT'].to_i >= 7)
    if filename = req.response_header['X_TMPFILENAME']
      File.unlink(filename)
    end
  end

  def test_streaming_download
    c = 0
    req = request {
      req = EventMachine::HttpRequest.new(@url + 'largebody').get
      req.stream do |chunk|
        c += 1
      end
      req
    }
    assert(c > 600)
  end

  if RUBY_VERSION > "1.9"
    def test_charset
      req = request {
        EventMachine::HttpRequest.new(@url + 'charset').get
      }
      body = req.response
      assert_equal(Encoding::EUC_JP, body.encoding)
      assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
    end
  end
end
