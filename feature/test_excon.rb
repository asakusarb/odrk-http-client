# -*- encoding: utf-8 -*-
require 'excon'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestExcon < OdrkHTTPClientTestCase
  def setup
    super
    @client = Excon
  end

  def test_ssl
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    assert_raise(Excon::Errors::SocketError) do
      @client.get(ssl_url + 'hello')
    end
  end

  def test_ssl_ca
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    ca_path = File.expand_path('./fixture/', File.dirname(__FILE__))
    @client.ssl_verify_peer = true
    @client.ssl_ca_path = ca_path
    assert_equal('hello ssl', @client.get(ssl_url + 'hello').body)
  end

  def test_ssl_hostname
    setup_sslserver
    ssl_url = "https://127.0.0.1:#{$ssl_port}/"
    ca_path = File.expand_path('./fixture/', File.dirname(__FILE__))
    @client.ssl_verify_peer = true
    @client.ssl_ca_path = ca_path
    assert_raise(Excon::Errors::SocketError) do
      @client.get(ssl_url + 'hello')
    end
  end

  def test_gzip_get
    assert_equal('hello', @client.get(@url + 'compressed?enc=gzip').body)
    assert_equal('hello', @client.get(@url + 'compressed?enc=deflate').body)
  end

  def test_gzip_post
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'gzip').body)
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'deflate').body)
  end

  def test_put
    assert_equal("put", @client.put(@url + 'servlet').body)
    res = @client.put(@url + 'servlet', :body => '1=2&3=4')
    # !! res.headers is a Hash, case sensitive
    assert_equal('1=2&3=4', res.headers["X-Query"])
    # bytesize
    res = @client.put(@url + 'servlet', :body => 'txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.headers["X-Query"])
    assert_equal('15', res.headers["X-Size"])
  end

  def test_delete
    assert_equal("delete", @client.delete(@url + 'servlet').body)
  end

  def test_cookies
    raise 'Cookie is not supported'
  end

  def test_post_multipart
    File.open(__FILE__) do |file|
      res = @client.post(@url + 'servlet', :upload => file)
      assert_match(/FIND_TAG_IN_THIS_FILE/, res.body)
    end
  end

  def test_basic_auth
    flunk('basic auth is not supported')
  end

  def test_digest_auth
    flunk('digest auth is not supported')
  end

  def test_redirect
    assert_equal('hello', @client.get(@url + 'redirect3').body)
  end

  def test_redirect_loop_detection
    assert_raise(RuntimeError) do
      @client.get(@url + 'redirect_self')
    end
  end

  def test_keepalive
    server = HTTPServer::KeepAliveServer.new($host)
    begin
      5.times do
        assert_equal('12345', @client.get(server.url).body)
      end
    ensure
      server.close
    end
    # chunked
    server = HTTPServer::KeepAliveServer.new($host)
    begin
      5.times do
        assert_equal('abcdefghijklmnopqrstuvwxyz1234567890abcdef', @client.get(server.url + 'chunked').body)
      end
    ensure
      server.close
    end
  end

  def test_streaming_download
    c = 0
    @client.get(@url + 'largebody') do |res|
      c += 1
    end
    assert_equal(10, c)
  end
end
