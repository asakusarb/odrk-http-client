# -*- encoding: utf-8 -*-
require 'test/unit'
require 'httparty'
require File.expand_path('./test_setting', File.dirname(__FILE__))
require File.expand_path('./httpserver', File.dirname(__FILE__))


class TestHTTParty < Test::Unit::TestCase
  class HTTPartyClient
    include HTTParty
  end

  def setup
    @server = HTTPServer.new($host, $port)
    proxy = URI.parse($proxy) if $proxy
    HTTPartyClient.http_proxy(proxy.host, proxy.port) if proxy
    @client = HTTPartyClient
    @client.debug_output(STDERR) if $DEBUG
    @url = $url
  end

  def teardown
    @server.shutdown
  end

  def test_gzip_get
    assert_equal('hello', @client.get(@url + 'compressed?enc=gzip'))
    assert_equal('hello', @client.get(@url + 'compressed?enc=deflate'))
  end

  def test_gzip_post
    assert_equal('hello', @client.post(@url + 'compressed', :body => {:enc => 'gzip'}))
    assert_equal('hello', @client.post(@url + 'compressed', :body => {:enc => 'deflate'}))
  end

  def test_put
    assert_equal("put", @client.put(@url + 'servlet', :body => '').body)
    res = @client.put(@url + 'servlet', :body => '1=2&3=4')
    assert_equal('1=2&3=4', res.header["x-query"])
    # bytesize
    res = @client.put(@url + 'servlet', :body => 'txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.header["x-query"])
    assert_equal('15', res.header["x-size"])
  end

  def test_delete
    assert_equal("delete", @client.delete(@url + 'servlet').body)
  end

  def test_cookies
    res = @client.get(@url + 'cookies', :headers => {'Cookie' => 'foo=0; bar=1'})
    # !! It's a String so you need to parse by yourself
    assert_equal(2, res.headers['Set-Cookie'].size)
    5.times do
      res = @client.get(@url + 'cookies')
    end
    assert_equal(2, @client.cookies.size)
    assert_equal('6', @client.cookies.find { |c| c.name == 'foo' }.value)
    assert_equal('7', @client.cookies.find { |c| c.name == 'bar' }.value)
  end

  def test_post_multipart
    flunk 'multipart form-data is not supported'
  end

  def test_basic_auth
    # !! Need to create Class each time...
    client = Class.new
    client.instance_eval { include HTTParty }
    client.basic_auth('admin', 'admin')
    assert_equal('basic_auth OK', client.get(@url + 'basic_auth').body)
  end

  def test_digest_auth
    client = Class.new
    client.instance_eval { include HTTParty }
    client.digest_auth('admin', 'admin')
    assert_equal('digest_auth OK', client.get(@url + 'digest_auth').body)
    # digest_sess
    flunk 'digest-sess auth is not supported'
  end

  def test_redirect
    assert_equal('hello', @client.get(@url + 'redirect3').body)
  end

  def test_redirect_loop_detection
    assert_raise(HTTParty::RedirectionTooDeep) do
      @client.get(@url + 'redirect_self', :limit => 10).body
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

