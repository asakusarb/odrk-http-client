# -*- encoding: utf-8 -*-
require 'rufus-verbs'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestRufusVerbs < OdrkHTTPClientTestCase
  include Rufus::Verbs

  def test_101_proxy
    setup_proxyserver
    assert_equal('hello', get(@url + 'hello', :proxy => @proxy_url).body)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_102_proxy_auth
    setup_proxyserver(true)
    proxy = URI.parse(@proxy_url)
    proxy.user = 'admin'
    proxy.password = 'admin'
    assert_equal('hello', get(@url + 'hello', :proxy => proxy.to_s).body)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_103_keepalive
  timeout(2) do
    server = HTTPServer::KeepAliveServer.new($host)
    begin
      5.times do
        assert_equal('12345', get(server.url).body)
      end
    ensure
      server.close
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
  end

  def test_104_pipelining
    flunk 'not supported'
  end

  def test_105_ssl
    setup_sslserver
    assert_raise(OpenSSL::SSL::SSLError) do
      get(@ssl_url + 'hello')
    end
  end

  def test_106_ssl_ca
    setup_sslserver
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    ENV['SSL_CERT_DIR'] = ca_file
    begin
      assert_equal('hello ssl', get(@ssl_url + 'hello', :ssl_verify_peer => true).body)
    ensure
      ENV.delete('SSL_CERT_DIR')
    end
  end

  def test_107_ssl_hostname
    setup_sslserver
    ENV['SSL_CERT_DIR'] = File.expand_path('./fixture/', File.dirname(__FILE__))
    begin
      assert_raise(OpenSSL::SSL::SSLError) do
        get(@ssl_fake_url + 'hello', :ssl_verify_peer => true)
      end
    ensure
      ENV.delete('SSL_CERT_DIR')
    end
  end

  def test_108_basic_auth
    assert_equal('basic_auth OK', get(@url + 'basic_auth', :http_basic_authentication => ['admin', 'admin']).body)
  end

  def test_109_digest_auth
    assert_equal('digest_auth OK', get(@url + 'digest_auth', :digest_authentication => ['admin', 'admin']).body)
    assert_equal('digest_sess_auth OK', get(@url + 'digest_sess_auth', :digest_authentication => ['admin', 'admin']).body)
  end

  def test_201_get
    assert_equal('hello', get(@url + 'hello').body)
  end

  def test_202_post
    assert_equal('hello', post(@url + 'hello', 'body').body)
  end

  def test_203_put
    assert_equal("put", put(@url + 'servlet').body)
    res = put(@url + 'servlet', :data => '1=2&3=4')
    assert_equal('1=2&3=4', res.header["x-query"])
    # bytesize
    res = put(@url + 'servlet', :data => 'txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.header["x-query"])
    assert_equal('15', res.header["x-size"])
  end

  def test_204_delete
    assert_equal("delete", delete(@url + 'servlet').body)
  end

  def test_205_custom_method
    flunk 'custom method not directly supported'
  end

  def test_206_response_header
    assert_match(/WEBrick/, get(@url + 'hello').header['server'])
  end

  def test_207_cookies
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
    assert_equal('6', c.find { |e| e.name == 'foo' }.value)
    assert_equal('7', c.find { |e| e.name == 'bar' }.value)
  end

  def test_208_redirect
    assert_equal('hello', get(@url + 'redirect3').body)
  end

  def test_209_redirect_loop_detection
    assert_raise(RuntimeError) do
      get(@url + 'redirect_self', :max_redirections => 10).body
    end
  end

  def test_2091_urlencoded
    assert_equal('1=2&3=4', post(@url + 'servlet', :data => {'1' => '2', '3' => '4'}).header["x-query"])
  end

  def test_210_post_multipart
    File.open(__FILE__) do |file|
      res = post(@url + 'servlet', :data => file)
      assert_match(/FIND_TAG_IN_THIS_FILE/, res.body)
    end
  end

  def test_211_streaming_upload
    flunk('streaming upload not supported')
  end

  def test_212_streaming_download
    flunk('streaming download not supported')
  end

  def test_213_gzip_get
    assert_equal('hello', get(@url + 'compressed?enc=gzip').body)
    assert_equal('hello', get(@url + 'compressed?enc=deflate').body)
  end

  def test_214_gzip_post
    assert_equal('hello', post(@url + 'compressed', :data => 'enc=gzip').body)
    assert_equal('hello', post(@url + 'compressed', :data => 'enc=deflate').body)
  end

  def test_215_charset
    body = get(@url + 'charset').body
    assert_equal(Encoding::EUC_JP, body.encoding)
    assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
  end
end
