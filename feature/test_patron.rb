# -*- encoding: utf-8 -*-
require 'test/unit'
require 'uri'
require 'patron'
require File.expand_path('./test_setting', File.dirname(__FILE__))
require File.expand_path('./httpserver', File.dirname(__FILE__))


class TestPatron < Test::Unit::TestCase
  def setup
    @server = HTTPServer.new($host, $port)
    @client = Patron::Session.new
    url = URI.parse($url)
    @client.base_url = (url + "/").to_s
    @url = url.path.sub(/^\//, '')
  end

  def teardown
    @server.shutdown
  end

  def test_gzip_get
    flunk 'patron is blocking; cannot test'
    assert_equal('hello', @client.get(@url + 'compressed?enc=gzip').body)
    assert_equal('hello', @client.get(@url + 'compressed?enc=deflate').body)
  end

  def test_gzip_post
    flunk 'patron is blocking; cannot test'
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'gzip').body)
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'deflate').body)
  end

  def test_put
    flunk 'patron is blocking; cannot test'
  end

  def test_delete
    flunk 'patron is blocking; cannot test'
  end

  def test_cookies
    flunk 'patron is blocking; cannot test'
  end
end
