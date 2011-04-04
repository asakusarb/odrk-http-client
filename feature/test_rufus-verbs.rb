# -*- encoding: utf-8 -*-
require 'test/unit'
require 'rufus-verbs'
require File.expand_path('./test_setting', File.dirname(__FILE__))
require File.expand_path('./httpserver', File.dirname(__FILE__))


class TestRufusVerbs < Test::Unit::TestCase

  include Rufus::Verbs

  def setup
    @server = HTTPServer.new($host, $port)
    @url = $url
    @proxy = $proxy
  end

  def teardown
    @server.shutdown
  end

  def test_gzip_get
    assert_equal('hello', get(@url + 'compressed?enc=gzip').body)
    assert_equal('hello', get(@url + 'compressed?enc=deflate').body)
  end

  def test_gzip_post
    assert_equal('hello', post(@url + 'compressed', :d => 'enc=gzip').body)
    assert_equal('hello', post(@url + 'compressed', :d => 'enc=deflate').body)
  end

  def test_put
    assert_equal("put", put(@url + 'servlet').body)
    res = put(@url + 'servlet', :d => '1=2&3=4')
    assert_equal('1=2&3=4', res.header["x-query"])
    # bytesize
    res = put(@url + 'servlet', :d => 'txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.header["x-query"])
    assert_equal('15', res.header["x-size"])
  end

  def test_delete
    assert_equal("delete", delete(@url + 'servlet').body)
  end

  def test_cookies
    ep = EndPoint.new(:cookies => true)
    # there's no direct way to set Cookie.
    ep.cookies.add_cookie('localhost', '/', Rufus::Verbs::Cookie.new('foo', '0'))
    ep.cookies.add_cookie('localhost', '/', Rufus::Verbs::Cookie.new('bar', '1'))
    res = ep.get(@url + 'cookies')
    assert_equal(2, ep.cookies.size)
    5.times do
      res = ep.get(@url + 'cookies')
    end
    assert_equal(2, ep.cookies.size)
    c = ep.cookies.fetch_cookies('localhost', '/')
    assert_equal('6', c.find { |c| c.name == 'foo' }.value)
    assert_equal('7', c.find { |c| c.name == 'bar' }.value)
  end

  def test_post_multipart
    File.open(__FILE__) do |file|
      res = post(@url + 'servlet', :d => {:upload => file})
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
end

