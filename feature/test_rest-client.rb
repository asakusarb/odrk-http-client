# -*- encoding: utf-8 -*-
require 'rest_client'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestRestClient < OdrkHTTPClientTestCase
  def setup
    super
    @client = RestClient
  end

  def test_ssl
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    @client = RestClient::Request.new(:method => :get, :url => ssl_url + 'hello')
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.execute
    end
  end

  def test_ssl_ca
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    @client = RestClient::Request.new(:method => :get, :url => ssl_url + 'hello', :verify_ssl => OpenSSL::SSL::VERIFY_PEER, :ssl_ca_file => ca_file)
    assert_equal('hello ssl', @client.execute.body)
  end

  def test_ssl_hostname
    setup_sslserver
    ssl_url = "https://127.0.0.1:#{$ssl_port}/"
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    @client = RestClient::Request.new(:method => :get, :url => ssl_url + 'hello', :verify_ssl => OpenSSL::SSL::VERIFY_PEER, :ssl_ca_file => ca_file)
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.execute
    end
  end

  def test_gzip_get
    assert_equal('hello', @client.get(@url + 'compressed?enc=gzip'))
    assert_equal('hello', @client.get(@url + 'compressed?enc=deflate'))
  end

  def test_gzip_post
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'gzip'))
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'deflate'))
  end

  def test_put
    assert_equal("put", @client.put(@url + 'servlet', ''))
    res = @client.put(@url + 'servlet', '1=2&3=4')
    assert_equal('1=2&3=4', res.headers[:x_query])
    # bytesize
    res = @client.put(@url + 'servlet', 'txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.headers[:x_query])
    assert_equal('15', res.headers[:x_size])
  end

  def test_delete
    assert_equal("delete", @client.delete(@url + 'servlet'))
  end

  def test_cookies
    res = @client.get(@url + 'cookies', :cookies => {:foo => '0', :bar => '1'})
    # It returns 3. It looks fail to parse expiry date. 'Expires' => 'Sun'
    assert_equal(2, res.cookies.size)
    5.times do
      res = @client.get(@url + 'cookies')
    end
    assert_equal(2, res.cookies.size)
    assert_equal('6', res.cookies.find { |c| c.name == 'foo' }.value)
    assert_equal('7', res.cookies.find { |c| c.name == 'bar' }.value)
  end

  def test_post_multipart
    File.open(__FILE__) do |file|
      res = @client.post(@url + 'servlet', :upload => file)
      assert_match(/FIND_TAG_IN_THIS_FILE/, res.body)
    end
  end

  def test_basic_auth
    resource = RestClient::Resource.new(@url + 'basic_auth', :user => 'admin', :password => 'admin')
    assert_equal('basic_auth OK', resource.get.body)
    # you can use http://user:pass@host/path style, too.
  end

  def test_digest_auth
    flunk 'digest auth is not supported'
    flunk 'digest-sess auth is not supported'
  end

  def test_redirect
    assert_equal('hello', @client.get(@url + 'redirect3').body)
  end

  def test_redirect_loop_detection
    timeout(2) do
      @client.get(@url + 'redirect_self').body
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
end

