# -*- encoding: utf-8 -*-
require 'excon'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestExcon < OdrkHTTPClientTestCase
  def setup
    super
    @client = Excon
  end

  def test_101_proxy
    setup_proxyserver
    client = Excon.new(@url + 'hello', :proxy => @proxy_url)
    assert_equal('hello', client.request(:method => :get).body)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_102_proxy_auth
    setup_proxyserver(true)
    client = Excon.new(@url + 'hello', :proxy => url_with_auth(@proxy_url, 'admin', 'admin'))
    assert_equal('hello', client.request(:method => :get).body)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_103_keepalive
    server = HTTPServer::KeepAliveServer.new($host)
    client = Excon.new(server.url)
    begin
      5.times do
        assert_equal('12345', client.request(:method => :get).body)
      end
    ensure
      server.close
    end
    # chunked
    server = HTTPServer::KeepAliveServer.new($host)
    client = Excon.new(server.url + 'chunked')
    begin
      5.times do
        assert_equal('abcdefghijklmnopqrstuvwxyz1234567890abcdef', client.request(:method => :get).body)
      end
    ensure
      server.close
    end
  end

  def test_104_pipelining
    flunk 'not supported'
  end

  def test_105_ssl
    setup_sslserver
    assert_raise(Excon::Errors::SocketError) do
      @client.get(@ssl_url + 'hello')
    end
  end

  def test_106_ssl_ca
    setup_sslserver
    ca_path = File.expand_path('./fixture/', File.dirname(__FILE__))
    @client.ssl_verify_peer = true
    @client.ssl_ca_path = ca_path
    assert_equal('hello ssl', @client.get(@ssl_url + 'hello').body)
  end

  def test_107_ssl_hostname
    setup_sslserver
    ca_path = File.expand_path('./fixture/', File.dirname(__FILE__))
    @client.ssl_verify_peer = true
    @client.ssl_ca_path = ca_path
    assert_raise(Excon::Errors::SocketError) do
      @client.get(@ssl_fake_url + 'hello')
    end
  end

  def test_108_basic_auth
    assert_equal('basic_auth OK', @client.get(url_with_auth(@url, 'admin', 'admin') + 'basic_auth').body)
  end

  def test_109_digest_auth
    assert_equal('digest_auth OK', @client.get(url_with_auth(@url, 'admin', 'admin') + 'digest_auth').body)
    # digest_sess
    assert_equal('digest_sess_auth OK', @client.get(url_with_auth(@url, 'admin', 'admin') + 'digest_sess_auth').body)
  end

  def test_201_get
    assert_equal('hello', @client.get(@url + 'hello').body)
  end

  def test_202_post
    assert_equal('hello', @client.post(@url + 'hello', :body => 'body').body)
  end

  def test_203_put
    assert_equal("put", @client.put(@url + 'servlet').body)
    res = @client.put(@url + 'servlet', :body => '1=2&3=4')
    # !! res.headers is a Hash, case sensitive
    assert_equal('1=2&3=4', res.headers["X-Query"])
    # bytesize
    res = @client.put(@url + 'servlet', :body => 'txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.headers["X-Query"])
    assert_equal('15', res.headers["X-Size"])
  end

  def test_204_delete
    assert_equal("delete", @client.delete(@url + 'servlet').body)
  end

  def test_205_custom_method
    res = Excon.new(@url + 'servlet?1=2&3=4').request(:method => :custom, :body => 'custom?')
    assert_equal('custom?', res.body)
    assert_equal('1=2&3=4', res.headers["X-Query"])
  end

  def test_206_response_header
    assert_match(/WEBrick/, @client.get(@url + 'hello').headers['Server'])
  end

  def test_207_cookies
    raise 'Cookie is not supported'
  end

  def test_208_redirect
    assert_equal('hello', @client.get(@url + 'redirect3').body)
  end

  def test_209_redirect_loop_detection
    assert_raise(RuntimeError) do
      @client.get(@url + 'redirect_self')
    end
  end

  def test_2091_urlencoded
    assert_equal('1=2&3=4', @client.post(@url + 'servlet', :body => {'1' => '2', '3' => '4'}).headers["X-Query"])
  end

  def test_210_post_multipart
    File.open(__FILE__) do |file|
      res = @client.post(@url + 'servlet', :upload => file)
      assert_match(/FIND_TAG_IN_THIS_FILE/, res.body)
    end
  end

  def test_211_streaming_upload
    flunk 'not supported'
  end

  def test_212_streaming_download
    c = 0
    @client.get(@url + 'largebody') do |res|
      c += 1
    end
    assert_equal(10, c)
  end

  def test_213_gzip_get
    assert_equal('hello', @client.get(@url + 'compressed?enc=gzip').body)
    assert_equal('hello', @client.get(@url + 'compressed?enc=deflate').body)
  end

  def test_214_gzip_post
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'gzip').body)
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'deflate').body)
  end

  def test_215_charset
    body = @client.get(@url + 'charset').body
    assert_equal(Encoding::EUC_JP, body.encoding)
    assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
  end
end
