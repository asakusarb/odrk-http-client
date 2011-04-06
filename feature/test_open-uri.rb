# -*- encoding: utf-8 -*-
require 'open-uri'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestOpenURI < OdrkHTTPClientTestCase
  def test_ssl
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    assert_raise(OpenSSL::SSL::SSLError) do
      open(ssl_url + 'hello') { |f| f.read }
    end
  end

  def test_ssl_ca
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    ca_path = File.expand_path('./fixture/', File.dirname(__FILE__))
    assert_equal('hello ssl', open(ssl_url + 'hello', :ssl_ca_cert => ca_path) { |f| f.read })
  end

  def test_ssl_hostname
    setup_sslserver
    ssl_url = "https://127.0.0.1:#{$ssl_port}/"
    ca_path = File.expand_path('./fixture/', File.dirname(__FILE__))
    assert_raise(OpenSSL::SSL::SSLError) do
      open(ssl_url + 'hello', :ssl_ca_cert => ca_path) { |f| f.read }
    end
  end

  def test_gzip_get
    assert_equal('hello', open(@url + 'compressed?enc=gzip') { |f| f.read })
    assert_equal('hello', open(@url + 'compressed?enc=deflate') { |f| f.read })
  end

  def test_gzip_post
    raise 'non-GET methods are not supported'
  end

  def test_post_multipart
    raise 'non-GET methods are not supported'
  end

  def test_basic_auth
    body = open(@url + 'basic_auth', :http_basic_authentication => ['admin', 'admin']) { |f| f.read }
    assert_equal('basic_auth OK', body)
  end

  def test_digest_auth
    flunk 'digest auth not supported'
    flunk 'digest-sess auth not supported'
  end

  def test_redirect
    body = open(@url + 'redirect3') { |f| f.read }
    assert_equal('hello', body)
  end

  def test_redirect_loop_detection
    assert_raise(RuntimeError) do
      open(@url + 'redirect_self') { |f| f.read }
    end
  end

  def test_keepalive
    server = HTTPServer::KeepAliveServer.new($host)
    timeout(2) do
      5.times do
        assert_equal('12345', open(server.url) { |f| f.read })
      end
    end
    server.close
  end

  def test_streaming_download
    c = 0
    open(@url + 'largebody') do |f|
      while f.read(16384)
        c += 1
      end
    end
    assert(c > 600)
  end

  if RUBY_VERSION > "1.9"
    def test_charset
      body = open(@url + 'charset') { |f| f.read }
      assert_equal(Encoding::EUC_JP, body.encoding)
      assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
    end
  end
end

