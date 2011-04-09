# -*- encoding: utf-8 -*-
require 'simplehttp'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestSimpleHTTP < OdrkHTTPClientTestCase
  def test_ssl
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    assert_raise(OpenSSL::SSL::SSLError) do
      SimpleHttp.new(ssl_url + 'hello').get
    end
  end

  def test_ssl_ca
    # !! this test should fail.
    # !! run SSL_CERT_DIR=./fixture/ ruby test_simplehttp.rb -n test_ssl_ca
    setup_sslserver
    ENV['SSL_CERT_DIR'] = File.expand_path('./fixture/', File.dirname(__FILE__))
    begin
      ssl_url = "https://localhost:#{$ssl_port}/"
      assert_equal('hello ssl', SimpleHttp.new(ssl_url + 'hello').get)
    ensure
      ENV.delete('SSL_CERT_DIR')
    end
  end

  def test_ssl_hostname
    # !! this test should fail.
    # !! run SSL_CERT_DIR=./fixture/ ruby test_simplehttp.rb -n test_ssl_hostname
    setup_sslserver
    ENV['SSL_CERT_DIR'] = File.expand_path('./fixture/', File.dirname(__FILE__))
    begin
      ssl_url = "https://127.0.0.1:#{$ssl_port}/"
      assert_raise(OpenSSL::SSL::SSLError) do
        SimpleHttp.new(ssl_url + 'hello').get
      end
    ensure
      ENV.delete('SSL_CERT_DIR')
    end
  end

  def test_gzip_get
    assert_equal('hello', SimpleHttp.new(@url + 'compressed?enc=gzip').get)
    assert_equal('hello', SimpleHttp.new(@url + 'compressed?enc=deflate').get)
  end

  def test_gzip_post
    assert_equal('hello', SimpleHttp.new(@url + 'compressed').post('enc' => 'gzip'))
    assert_equal('hello', SimpleHttp.new(@url + 'compressed').post('enc' => 'deflate'))
  end

  def test_put
    assert_equal("put", SimpleHttp.new(@url + 'servlet').put)
  end

  def test_delete
    assert_equal("delete", SimpleHttp.new(@url + 'servlet').delete)
  end

  def test_cookies
    flunk 'not supported (do it by yourself)'
  end

  def test_post_multipart
    File.open(__FILE__) do |file|
      res = SimpleHttp.new(@url + 'servlet').post('upload' => file)
      assert_match(/FIND_TAG_IN_THIS_FILE/, res.body)
    end
  end

  def test_basic_auth
    client = SimpleHttp.new(@url + 'basic_auth')
    client.basic_authentication('admin', 'admin')
    assert_equal('basic_auth OK', client.get)
  end

  def test_digest_auth
    flunk 'digest auth is not supported'
    flunk 'digest sess auth is not supported'
  end

  def test_redirect
    assert_equal('hello', SimpleHttp.new(@url + 'redirect3').get)
  end

  def test_redirect_loop_detection
    h = SimpleHttp.new(@url + 'redirect_self')
    h.follow_num_redirects = 10
    assert_raise(RuntimeError) do
      h.get
    end
  end

  def test_keepalive
    server = HTTPServer::KeepAliveServer.new($host)
    timeout(2) do
      begin
        5.times do
          assert_equal('12345', SimpleHttp.new(server.url).get)
        end
      ensure
        server.close
      end
    end
    # chunked
    server = HTTPServer::KeepAliveServer.new($host)
    begin
      5.times do
        assert_equal('abcdefghijklmnopqrstuvwxyz1234567890abcdef', SimpleHttp.new(server.url + 'chunked').get)
      end
    ensure
      server.close
    end
  end

  def test_streaming_download
    flunk('streaming download not supported')
  end

  if RUBY_VERSION > "1.9"
    def test_charset
      body = SimpleHttp.new(@url + 'charset').get
      assert_equal(Encoding::EUC_JP, body.encoding)
      assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
    end
  end
end

