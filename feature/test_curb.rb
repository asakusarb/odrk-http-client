# -*- encoding: utf-8 -*-
require 'curb'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestCurb < OdrkHTTPClientTestCase
  def test_ssl
    setup_sslserver
    ssl_url = "https://ubuntu:#{$ssl_port}/"
    assert_raise(OpenSSL::SSL::SSLError) do
      Curl::Easy.http_get(ssl_url + 'hello')
    end
  end

  def test_ssl_ca
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    easy = Curl::Easy.new(ssl_url + 'hello')
    easy.cacert = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    easy.http_get
    assert_equal('hello ssl', easy.body_str)
  end

  def test_ssl_hostname
    setup_sslserver
    ssl_url = "https://127.0.0.1:#{$ssl_port}/"
    easy = Curl::Easy.new(ssl_url + 'hello')
    easy.cacert = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    assert_raise(OpenSSL::SSL::SSLError) do
      easy.http_get
    end
  end

  def test_gzip_get
    easy = Curl::Easy.new(@url + 'compressed?enc=gzip')
    easy.encoding = 'gzip'
    easy.http_get
    assert_equal('hello', easy.body_str)
    easy = Curl::Easy.new(@url + 'compressed?enc=deflate')
    easy.encoding = 'deflate'
    easy.http_get
    assert_equal('hello', easy.body_str)
  end

  def test_gzip_post
    easy = Curl::Easy.new(@url + 'compressed')
    easy.encoding = 'gzip'
    easy.http_post(Curl::PostField.content('enc', 'gzip'))
    assert_equal('hello', easy.body_str)
    #
    easy = Curl::Easy.new(@url + 'compressed')
    easy.encoding = 'deflate'
    easy.http_post(Curl::PostField.content('enc', 'deflate'))
    assert_equal('hello', easy.body_str)
  end

  def test_put
    assert_equal("put", Curl::Easy.http_put(@url + 'servlet', '').body_str)
    res = Curl::Easy.http_put(@url + 'servlet', '1=2&3=4')
    assert_match(/X-Query: 1=2&3=4/, res.header_str)
    # bytesize
    res = Curl::Easy.http_put(@url + 'servlet', 'txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_match(/X-Query: txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A/, res.header_str)
    assert_match(/X-Size: 15/, res.header_str)
  end

  def test_delete
    assert_equal("delete", Curl::Easy.http_delete(@url + 'servlet').body_str)
  end

  def test_cookies
    easy = Curl::Easy.new(@url + 'cookies')
    easy.enable_cookies = true
    easy.cookiefile = "some.file"
    easy.cookies = 'foo=0;bar=1'
    easy.http_get
    /foo=(\d)/ =~ easy.header_str
    assert_equal('1', $1)
    /bar=(\d)/ =~ easy.header_str
    assert_equal('2', $1)
    5.times do
      easy.cookies = ''
      easy.http_get
    end
    /foo=(\d)/ =~ easy.header_str
    assert_equal('6', $1)
    /bar=(\d)/ =~ easy.header_str
    assert_equal('7', $1)
  end

  def test_post_multipart
    easy = Curl::Easy.new(@url + 'servlet')
    easy.multipart_form_post = true
    easy.http_post(Curl::PostField.file('upload', __FILE__))
    assert_match(/FIND_TAG_IN_THIS_FILE/, easy.body_str)
  end

  def test_basic_auth
    easy = Curl::Easy.new(@url + 'basic_auth')
    easy.http_auth_types = :basic
    easy.username = 'admin'
    easy.password = 'admin'
    easy.http_get
    assert_equal('basic_auth OK', easy.body_str)
  end

  def test_digest_auth
    easy = Curl::Easy.new(@url + 'digest_auth')
    easy.http_auth_types = :digest
    easy.username = 'admin'
    easy.password = 'admin'
    easy.http_get
    assert_equal('digest_auth OK', easy.body_str)
    # sess
    easy = Curl::Easy.new(@url + 'digest_sess_auth')
    easy.http_auth_types = :digest
    easy.username = 'admin'
    easy.password = 'admin'
    easy.http_get
    assert_equal('digest_sess_auth OK', easy.body_str)
  end

  def test_redirect
    easy = Curl::Easy.new(@url + 'redirect3')
    easy.follow_location = true
    easy.http_get
    assert_equal('hello', easy.body_str)
  end

  def test_redirect_loop_detection
    easy = Curl::Easy.new(@url + 'redirect_self')
    easy.max_redirects = 10
    easy.follow_location = true
    assert_raises(Curl::Err::TooManyRedirectsError) do
      easy.http_get
    end
  end

  def test_keepalive
    server = HTTPServer::KeepAliveServer.new($host)
    begin
      easy = Curl::Easy.new(server.url)
      5.times do
        easy.http_get
        assert_equal('12345', easy.body_str)
      end
    ensure
      server.close
    end
    # chunked
    server = HTTPServer::KeepAliveServer.new($host)
    begin
      easy = Curl::Easy.new(server.url + 'chunked')
      5.times do
        easy.http_get
        assert_equal('abcdefghijklmnopqrstuvwxyz1234567890abcdef', easy.body_str)
      end
    ensure
      server.close
    end
  end
end

