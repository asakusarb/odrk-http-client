# -*- encoding: utf-8 -*-
require 'test/unit'
require 'open-uri'
require File.expand_path('./test_setting', File.dirname(__FILE__))
require File.expand_path('./httpserver', File.dirname(__FILE__))


class TestOpenURI < Test::Unit::TestCase
  def setup
    @server = HTTPServer.new($host, $port)
    if $proxy_user
      @opt = {:proxy_http_basic_authentication => [$proxy, $proxy_user, $proxy_pass]}
    elsif @proxy
      @opt = {:proxy => $proxy}
    else
      @opt = {}
    end
    @url = $url
  end

  def teardown
    @server.shutdown
  end

  def test_gzip_get
    assert_equal('hello', open(@url + 'compressed?enc=gzip', @opt) { |f| f.read })
    assert_equal('hello', open(@url + 'compressed?enc=deflate', @opt) { |f| f.read })
  end

  def test_gzip_post
    raise 'non-GET methods are not supported'
  end

  def test_post_multipart
    raise 'non-GET methods are not supported'
  end

  def test_basic_auth
    body = open(@url + 'basic_auth', :http_basic_authentication => ['admin', 'admin']) { |f| f.read }
    assert_equal('basic_auth OK', body)
  end

  def test_digest_auth
    flunk 'digest auth not supported'
    flunk 'digest-sess auth not supported'
  end

  def test_redirect
    body = open(@url + 'redirect3') { |f| f.read }
    assert_equal('hello', body)
  end

  def test_redirect_loop_detection
    assert_raise(RuntimeError) do
      open(@url + 'redirect_self') { |f| f.read }
    end
  end

  def test_keepalive
    server = HTTPServer::KeepAliveServer.new($host)
    5.times do
      assert_equal('12345', open(server.url) { |f| f.read })
    end
    server.close
  end
end

