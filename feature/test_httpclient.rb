# -*- encoding: utf-8 -*-
require 'test/unit'
require 'httpclient'
require File.expand_path('./test_setting', File.dirname(__FILE__))
require File.expand_path('./httpserver', File.dirname(__FILE__))


class TestHTTPClient < Test::Unit::TestCase
  def setup
    @server = HTTPServer.new($host, $port)
    @client = HTTPClient.new($proxy)
    @url = $url
  end

  def teardown
    @server.shutdown
  end

  def test_gzip_get
    @client.transparent_gzip_decompression = true
    assert_equal('hello', @client.get(@url + 'compressed?enc=gzip').body)
    assert_equal('hello', @client.get(@url + 'compressed?enc=deflate').body)
    @client.transparent_gzip_decompression = false
  end

  def test_gzip_post
    @client.transparent_gzip_decompression = true
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'gzip').body)
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'deflate').body)
    @client.transparent_gzip_decompression = false
  end

  def test_put
    assert_equal("put", @client.put(@url + 'servlet').body)
    res = @client.put(@url + 'servlet', {1=>2, 3=>4})
    assert_equal('1=2&3=4', res.header["x-query"][0])
    # bytesize
    res = @client.put(@url + 'servlet', 'txt' => 'あいうえお')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.header["x-query"][0])
    assert_equal('15', res.header["x-size"][0])
  end

  def test_delete
    assert_equal("delete", @client.delete(@url + 'servlet').body)
  end

  def test_cookies
    res = @client.get(@url + 'cookies', :header => {'Cookie' => 'foo=0; bar=1'})
    assert_equal(2, @client.cookies.size)
    5.times do
      res = @client.get(@url + 'cookies')
    end
    assert_equal(2, @client.cookies.size)
    assert_equal('6', @client.cookies.find { |c| c.name == 'foo' }.value)
    assert_equal('7', @client.cookies.find { |c| c.name == 'bar' }.value)
  end

  def test_post_multipart
    File.open(__FILE__) do |file|
      res = @client.post(@url + 'servlet', :upload => file)
      assert_match(/FIND_TAG_IN_THIS_FILE/, res.body)
    end
  end

  def test_basic_auth
    @client.set_auth(@url, 'admin', 'admin')
    assert_equal('basic_auth OK', @client.get(@url + 'basic_auth').body)
  end

  def test_digest_auth
    @client.set_auth(@url, 'admin', 'admin')
    assert_equal('digest_auth OK', @client.get(@url + 'digest_auth').body)
    # digest_sess
    @client.set_auth(@url, 'admin', 'admin')
    assert_equal('digest_sess_auth OK', @client.get(@url + 'digest_sess_auth').body)
  end

  def test_redirect
    assert_equal('hello', @client.get_content(@url + 'redirect3'))
  end

  def test_redirect_loop_detection
    assert_raise(HTTPClient::BadResponseError) do
      @client.protocol_retry_count = 10
      @client.get_content(@url + 'redirect_self')
    end
  end
end
