# -*- encoding: utf-8 -*-
require 'test/unit'
require 'simplehttp'
require File.expand_path('./test_setting', File.dirname(__FILE__))
require File.expand_path('./httpserver', File.dirname(__FILE__))


class TestSimpleHTTP < Test::Unit::TestCase
  def setup
    @server = HTTPServer.new($host, $port)
    @url = $url
  end

  def teardown
    @server.shutdown
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
    res = SimpleHttp.new(@url + 'servlet').put('1=2&3=4')
    assert_equal('1=2&3=4', res.header["x-query"])
    # bytesize
    res = SimpleHttp.new(@url + 'servlet').put('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.header["x-query"])
    assert_equal('15', res.header["x-size"])
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
end

