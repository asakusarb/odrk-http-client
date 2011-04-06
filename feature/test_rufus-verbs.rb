# -*- encoding: utf-8 -*-
require 'rufus-verbs'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestRufusVerbs < OdrkHTTPClientTestCase
  include Rufus::Verbs

  def test_ssl
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    assert_raise(OpenSSL::SSL::SSLError) do
      get(ssl_url + 'hello')
    end
  end

  def test_ssl_ca
    setup_sslserver
    ENV['SSL_CERT_DIR'] = File.expand_path('./fixture/', File.dirname(__FILE__))
    begin
      ssl_url = "https://localhost:#{$ssl_port}/"
      assert_equal('hello ssl', get(ssl_url + 'hello', :ssl_verify_peer => true).body)
    ensure
      ENV.delete('SSL_CERT_DIR')
    end
  end

  def test_ssl_hostname
    setup_sslserver
    ENV['SSL_CERT_DIR'] = File.expand_path('./fixture/', File.dirname(__FILE__))
    begin
      ssl_url = "https://127.0.0.1:#{$ssl_port}/"
      assert_raise(OpenSSL::SSL::SSLError) do
        get(ssl_url + 'hello', :ssl_verify_peer => true)
      end
    ensure
      ENV.delete('SSL_CERT_DIR')
    end
  end

  def test_gzip_get
    assert_equal('hello', get(@url + 'compressed?enc=gzip').body)
    assert_equal('hello', get(@url + 'compressed?enc=deflate').body)
  end

  def test_gzip_post
    assert_equal('hello', post(@url + 'compressed', :data => 'enc=gzip').body)
    assert_equal('hello', post(@url + 'compressed', :data => 'enc=deflate').body)
  end

  def test_put
    assert_equal("put", put(@url + 'servlet').body)
    res = put(@url + 'servlet', :data => '1=2&3=4')
    assert_equal('1=2&3=4', res.header["x-query"])
    # bytesize
    res = put(@url + 'servlet', :data => 'txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.header["x-query"])
    assert_equal('15', res.header["x-size"])
  end

  def test_delete
    assert_equal("delete", delete(@url + 'servlet').body)
  end

  def test_cookies
    ep = EndPoint.new(:cookies => true)
    # there's no direct way to set Cookie.
    ep.cookies.add_cookie($host, '/', Rufus::Verbs::Cookie.new('foo', '0'))
    ep.cookies.add_cookie($host, '/', Rufus::Verbs::Cookie.new('bar', '1'))
    res = ep.get(@url + 'cookies')
    assert_equal(2, ep.cookies.size)
    5.times do
      res = ep.get(@url + 'cookies')
    end
    assert_equal(2, ep.cookies.size)
    c = ep.cookies.fetch_cookies($host, '/')
    assert_equal('6', c.find { |c| c.name == 'foo' }.value)
    assert_equal('7', c.find { |c| c.name == 'bar' }.value)
  end

  def test_post_multipart
    File.open(__FILE__) do |file|
      res = post(@url + 'servlet', :data => {:upload => file})
      assert_match(/FIND_TAG_IN_THIS_FILE/, res.body)
    end
  end

  def test_basic_auth
    assert_equal('basic_auth OK', get(@url + 'basic_auth', :http_basic_authentication => ['admin', 'admin']).body)
  end

  def test_digest_auth
    assert_equal('digest_auth OK', get(@url + 'digest_auth', :digest_authentication => ['admin', 'admin']).body)
    assert_equal('digest_sess_auth OK', get(@url + 'digest_sess_auth', :digest_authentication => ['admin', 'admin']).body)
  end

  def test_redirect
    assert_equal('hello', get(@url + 'redirect3').body)
  end

  def test_redirect_loop_detection
    assert_raise(RuntimeError) do
      get(@url + 'redirect_self', :max_redirections => 10).body
    end
  end

  def test_keepalive
    server = HTTPServer::KeepAliveServer.new($host)
    timeout(2) do
      begin
        5.times do
          assert_equal('12345', get(server.url).body)
        end
      ensure
        server.close
      end
    end
    # chunked
    server = HTTPServer::KeepAliveServer.new($host)
    begin
      5.times do
        assert_equal('abcdefghijklmnopqrstuvwxyz1234567890abcdef', get(server.url + 'chunked').body)
      end
    ensure
      server.close
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
      body = get(@url + 'charset').body
      assert_equal(Encoding::EUC_JP, body.encoding)
      assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
    end
  end
end

