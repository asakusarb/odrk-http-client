# -*- encoding: utf-8 -*-
require 'test/unit'
require 'typhoeus'
require File.expand_path('./test_setting', File.dirname(__FILE__))
require File.expand_path('./httpserver', File.dirname(__FILE__))


class TestTyphoeus < Test::Unit::TestCase
  def setup
    @server = HTTPServer.new($host, $port)
    @client = Typhoeus::Request
    @url = $url
  end

  def teardown
    @server.shutdown
  end

  def test_gzip_get
    assert_equal('hello', @client.get(@url + 'compressed?enc=gzip').body)
    assert_equal('hello', @client.get(@url + 'compressed?enc=deflate').body)
  end

  def test_gzip_post
    assert_equal('hello', @client.post(@url + 'compressed', :params => {:enc => 'gzip'}).body)
    assert_equal('hello', @client.post(@url + 'compressed', :params => {:enc => 'deflate'}).body)
  end

  def test_post
    res = @client.post(@url + 'servlet', :params => {1=>2, 3=>4})
    res = @client.post(@url + 'servlet', :params => {1=>2, 3=>4})
  end

  def test_put
    assert_equal("put", @client.put(@url + 'servlet').body)
    res = @client.put(@url + 'servlet', :body => '1=2&3=4')
    # !! res.headers is a String.
    assert_match(/X-Query: 1=2&3=4/, res.headers)
    # bytesize
    res = @client.put(@url + 'servlet', :body => 'txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_match(/X-Query: txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A/, res.headers)
    assert_match(/X-Size: 15/, res.headers)
  end

  def test_delete
    assert_equal("delete", @client.delete(@url + 'servlet').body)
  end

  def test_cookies
    res = @client.get(@url + 'cookies', :header => {'Cookie' => 'foo=0; bar=1'})
    assert_equal(2, res.cookies.size)
    5.times do
      res = @client.get(@url + 'cookies')
    end
    assert_equal(2, @client.cookies.size)
    assert_equal('6', @client.cookies.find { |c| c.name == 'foo' }.value)
    assert_equal('7', @client.cookies.find { |c| c.name == 'bar' }.value)
  end

  def test_post_multipart
    # we cannot use Typhoeus::Request?
    flunk 'typhous blocks when posting. wired...'
    easy = Typhoeus::Easy.new
    easy.url = @url + 'servlet'
    easy.method = :post
    easy.params = {:upload => __FILE__}
    easy.perform
    assert_match(/FIND_TAG_IN_THIS_FILE/, easy.body_str)
  end

  def test_basic_auth
    assert_equal('basic_auth OK', Typhoeus::Request.get(@url + 'basic_auth', :username => 'admin', :password => 'admin', :auth_method => :basic).body)
  end

  def test_digest_auth
    assert_equal('digest_auth OK', Typhoeus::Request.get(@url + 'digest_auth', :username => 'admin', :password => 'admin', :auth_method => :digest).body)
    # digest_sess
    assert_equal('digest_sess_auth OK', Typhoeus::Request.get(@url + 'digest_sess_auth', :username => 'admin', :password => 'admin', :auth_method => :digest).body)
  end

  def test_redirect
    res = Typhoeus::Request.get(@url + 'redirect3', :follow_location => true)
    assert_equal('hello', res.body)
  end

  def test_redirect_loop_detection
    res = Typhoeus::Request.get(@url + 'redirect_self', :follow_location => true, :max_redirects => 10)
    assert_equal("Number of redirects hit maximum amount", res.curl_error_message)
  end
end
