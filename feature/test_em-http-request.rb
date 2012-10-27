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

  def test_101_proxy
    setup_proxyserver
    url = URI.parse(@url)
    proxy = URI.parse(@proxy_url)
    req = request {
      EventMachine::HttpRequest.new(@url + 'hello', :proxy => {:host => proxy.host, :port => proxy.port}).get
    }
    assert_equal('hello', req.response)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_102_proxy_auth
    setup_proxyserver(true)
    url = URI.parse(@url)
    proxy = URI.parse(@proxy_url)
    req = request {
      EventMachine::HttpRequest.new(@url + 'hello', :proxy => {:host => proxy.host, :port => proxy.port, :authorization => ['admin', 'admin']}).get
    }
    assert_equal('hello', req.response)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_103_keepalive
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
    assert_equal(1, body.uniq.size)
    assert_equal('12345', body[0])
    server.close
    # chunked
    server = HTTPServer::KeepAliveServer.new($host)
    body = []
    EM.run do
      conn = EventMachine::HttpRequest.new(server.url + 'chunked')
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
    assert_equal(1, body.uniq.size)
    assert_equal('abcdefghijklmnopqrstuvwxyz1234567890abcdef', body[0])
    server.close
  end

  def test_104_pipelining
    flunk 'not supported'
  end

  def test_105_ssl
    setup_sslserver
    EM.run do
      req = EventMachine::HttpRequest.new(@ssl_url + 'hello').get
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

  def test_106_ssl_ca
    # The parameter :cert_chain_file of EventMachine is the certificate chain sent to the server, which is not related to verification. SSL client of EventMachine does not support SSL verification (just fail for :verify_peer => true)
    flunk('SSL configuration not supported')
  end

  def test_107_ssl_hostname
    setup_sslserver
    EM.run do
      opt = {:tls => {:verify_peer => true}}
      req = EventMachine::HttpRequest.new(@ssl_fake_url + 'hello', opt).get
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

  def test_108_basic_auth
    req = request {
      EventMachine::HttpRequest.new(@url + 'basic_auth').get(:head => {:authorization => ['admin', 'admin']})
    }
    assert_equal('basic_auth OK', req.response)
  end

  def test_109_digest_auth
    flunk 'digest auth not supported'
  end

  def test_201_get
    assert_equal('hello', request { EventMachine::HttpRequest.new(@url + 'hello').get }.response)
  end

  def test_202_post
    assert_equal('hello', request { EventMachine::HttpRequest.new(@url + 'hello').post(:body => 'body') }.response)
  end

  def test_203_put
    assert_equal('put', request { EventMachine::HttpRequest.new(@url + 'servlet').put(:body => '') }.response)
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

  def test_204_delete
    req = request {
      EventMachine::HttpRequest.new(@url + 'servlet').delete
    }
    assert_equal("delete", req.response)
  end

  def test_205_custom_method
    req = request {
      EventMachine::HttpRequest.new(@url + 'servlet?1=2&3=4').setup_request('custom', :body => 'custom?')
    }
    assert_equal('custom?', req.response)
    assert_equal('1=2&3=4', req.response_header["X_QUERY"])
  end

  def test_207_cookies
    req = request { EventMachine::HttpRequest.new(@url + 'cookies').get(:head => {:cookie => 'foo=0; bar=1'}) }
    assert_equal(2, req.response_header.cookie.size)
    5.times do
      req = request { EventMachine::HttpRequest.new(@url + 'cookies').get }
    end
    assert_equal(2, req.response_header.cookie.size)
    assert_equal('6', @client.cookies.find { |c| c.name == 'foo' }.value)
    assert_equal('7', @client.cookies.find { |c| c.name == 'bar' }.value)
  end

  def test_208_redirect
    req = request {
      EventMachine::HttpRequest.new(@url + 'redirect3').get(:redirects => 3)
    }
    assert_equal('hello', req.response)
  end

  def test_209_redirect_loop_detection
    req = request {
      EventMachine::HttpRequest.new(@url + 'redirect_self').get(:redirects => 3)
    }
  end

  def test_2091_urlencoded
    assert_equal('1=2&3=4', request { EventMachine::HttpRequest.new(@url + 'servlet').post(:body => {'1' => '2', '3' => '4'}) }.response_header["X_QUERY"])
  end

  def test_210_post_multipart
    # !! How can I run this? https://gist.github.com/778639
    # Where're the definitions for MultipartBody, Part and Multipart?
    File.open(__FILE__) do |file|
      req = request {
        EventMachine::HttpRequest.new(@url + 'servlet').post(:body => file)
      }
      assert_match(/FIND_TAG_IN_THIS_FILE/, req.response)
    end
  end

  def test_211_streaming_upload
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

  def test_212_streaming_download
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

  def test_213_gzip_get
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

  def test_214_gzip_post
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

  def test_215_charset
    req = request {
      EventMachine::HttpRequest.new(@url + 'charset').get
    }
    body = req.response
    assert_equal(Encoding::EUC_JP, body.encoding)
    assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
  end

  def test_216_iri
    server = HTTPServer::IRIServer.new($host)
    req = request {
      EventMachine::HttpRequest.new(server.url + 'hello?q=grebe-camilla-träff-åsa-norlen-paul/').get
    }
    assert_equal('hello', req.response)
    server.close
  end
end
