# -*- encoding: utf-8 -*-
require 'wrest'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestWrest < OdrkHTTPClientTestCase
  def setup
    super
    Wrest.use_native! # use net/http. Cannot use Patron because it's blocking.
  end

  def test_ssl
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    assert_raise(OpenSSL::SSL::SSLError) do
      ssl_url.to_uri.get
    end
  end

  def test_ssl_ca
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    ca_path = File.expand_path('./fixture/', File.dirname(__FILE__))
    assert_equal('hello ssl', (ssl_url + 'hello').to_uri(:ca_path => ca_path).get.body)
  end

  def test_ssl_hostname
    setup_sslserver
    ssl_url = "https://127.0.0.1:#{$ssl_port}/"
    ca_path = File.expand_path('./fixture/', File.dirname(__FILE__))
    assert_raise(OpenSSL::SSL::SSLError) do
      (ssl_url + 'hello').to_uri(:ca_path => ca_path).get
    end
  end

  def test_gzip_get
    assert_equal('hello', (@url + 'compressed?enc=gzip').to_uri.get.body)
    assert_equal('hello', (@url + 'compressed?enc=deflate').to_uri.get.body)
  end

  def test_gzip_post
    assert_equal('hello', (@url + 'compressed').to_uri.post('enc=gzip').body)
    assert_equal('hello', (@url + 'compressed').to_uri.post('enc=deflate').body)
  end

  def test_put
    assert_equal("put", (@url + 'servlet').to_uri.put.body)
    res = (@url + 'servlet').to_uri.put('1=2&3=4')
    assert_equal('1=2&3=4', res.headers["x-query"])
    # bytesize
    res = (@url + 'servlet').to_uri.put('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.headers["x-query"])
    assert_equal('15', res.headers["x-size"])
  end

  def test_delete
    assert_equal("delete", (@url + 'servlet').to_uri.delete.body)
  end

  def test_cookies
    flunk('Cookie is not supported')
  end

  def test_post_multipart
    require 'wrest/multipart'
    File.open(__FILE__) do |file|
      res = (@url + 'servlet').to_uri.post_multipart(:upload => Wrest::Native::PostMultipart::UploadIO.new(file, 'text/plain'))
      assert_match(/FIND_TAG_IN_THIS_FILE/, res.body)
    end
  end

  def test_basic_auth
    assert_equal('basic_auth OK', (@url + 'basic_auth').to_uri(:username => 'admin', :password => 'admin').get.body)
  end

  def test_digest_auth
    flunk('digest auth not supported')
  end

  def test_redirect
    assert_equal('hello', (@url + 'redirect3').to_uri.get.body)
  end

  def test_redirect_loop_detection
    assert_raise(Wrest::Exceptions::AutoRedirectLimitExceeded) do
      (@url + 'redirect_self').to_uri(:follow_redirects_limit => 10).get
    end
  end

  def test_keepalive
    server = HTTPServer::KeepAliveServer.new($host)
    begin
      Wrest::Http::Session.new(server.url) do |s|
        5.times do
          assert_equal('12345', s.get('/').body)
        end
      end
    ensure
      server.close
    end
    # chunked
    server = HTTPServer::KeepAliveServer.new($host)
    begin
      Wrest::Http::Session.new(server.url) do |s|
        5.times do
          assert_equal('abcdefghijklmnopqrstuvwxyz1234567890abcdef', s.get('/chunked').body)
        end
      end
    ensure
      server.close
    end
  end

  def test_streaming_upload
    file = Tempfile.new(__FILE__)
    file << "*" * 4096 * 100
    file.close
    file.open
    req = Net::HTTP::Post.new(@url + 'chunked')
    req.body_stream = file
    # !! should be set by body_stream=
    req['Transfer-Encoding'] = 'chunked'
    res = @client.request(req)
    assert(res.header['x-count'].to_i >= 100)
    if filename = res.header['x-tmpfilename']
      File.unlink(filename)
    end
  end

  def test_streaming_upload
    flunk('streaming upload not supported')
  end

  def test_streaming_download
    flunk('streaming download not supported')
  end

  if RUBY_VERSION > "1.9"
    def test_charset
      body = (@url + 'charset').to_uri.get.body
      assert_equal(Encoding::EUC_JP, body.encoding)
      assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
    end
  end
end
