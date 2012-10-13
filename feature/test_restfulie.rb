# -*- encoding: utf-8 -*-
require 'restfulie'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestRestfulie < OdrkHTTPClientTestCase
  def setup
    super
    @client = Restfulie
  end

  def test_proxy
    flunk 'not supported'
  end

  def test_proxy_auth
    flunk 'not supported'
  end

  def test_keepalive
    flunk 'not supported'
  end

  def test_pipelining
    flunk 'not supported'
  end

  def test_ssl
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    assert_raise(Restfulie::Client::HTTP::Error::ServerNotAvailableError) do
      @client.at(ssl_url + 'hello').get!
    end
    assert_equal(OpenSSL::SSL::SSLError, @client.at(ssl_url + 'hello').get.class)
  end

  def test_ssl_ca
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    flunk 'not supported'
  end

  def test_ssl_hostname
    setup_sslserver
    ssl_url = "https://127.0.0.1:#{$ssl_port}/"
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    flunk 'not supported'
  end

  def test_basic_auth
    url = URI.parse(@url.to_s)
    url.user = 'admin'
    url.password = 'admin'
    assert_equal('basic_auth OK', @client.at(url.to_s + 'basic_auth').get!.body)
  end

  def test_digest_auth
    flunk 'not supported'
  end

  def test_get
    assert_equal('hello', @client.at(@url + 'hello').get!.body)
  end

  def test_post
    assert_equal('post,hello', @client.at(@url + 'servlet').with('Content-Type' => 'plain/text').post("hello").body)
  end

  def test_put
    assert_equal("put", @client.at(@url + 'servlet').with('Content-Type' => 'plain/text').put!('body').body)
    res = @client.at(@url + 'servlet').with('Content-Type' => 'application/x-www-form-urlencoded').put!("1=2&3=4")
    assert_equal('1=2&3=4', res.header["x-query"])
    # bytesize
    res = @client.at(@url + 'servlet').with('Content-Type' => 'application/x-www-form-urlencoded').put!('txt=あいうえお')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.header["x-query"])
    assert_equal('15', res.header["x-size"])
  end

  def test_delete
    assert_equal("delete", @client.at(@url + 'servlet').delete!.body)
  end

  def test_custom_method
    flunk 'not supported'
  end

  def test_response_header
    assert_match(/WEBrick/, @client.at(@url + 'hello').get!.headers['server'][0])
  end

  def test_cookies
    flunk 'not supported'
  end

  def test_redirect
    assert_equal('hello', @client.at(@url + 'redirect3').get!.body)
  end

  def test_redirect_loop_detection
    timeout(2) do
      @client.at(@url + 'redirect_self').get!.body
    end
  end

  def test_post_multipart
    flunk 'not supported'
  end

  def test_streaming_upload
    flunk 'not supported'
  end

  def test_streaming_download
    flunk 'not supported'
  end

  def test_gzip_get
    assert_equal('hello', @client.at(@url + 'compressed?enc=gzip').get.body)
    assert_equal('hello', @client.at(@url + 'compressed?enc=deflate').get.body)
  end

  def test_gzip_post
    assert_equal('hello', @client.at(@url + 'compressed').with('Content-Type' => 'application/x-www-form-urlencoded', 'Accept-Encoding' => 'gzip').post("enc=gzip").body)
    assert_equal('hello', @client.at(@url + 'compressed').with('Content-Type' => 'application/x-www-form-urlencoded', 'Accept-Encoding' => 'deflate').post("enc=deflate").body)
  end

  def test_charset
    body = @client.at(@url + 'charset').get!.body
    assert_equal(Encoding::EUC_JP, body.encoding)
    assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
  end
end

