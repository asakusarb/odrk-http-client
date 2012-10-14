# -*- encoding: utf-8 -*-
require 'restfulie'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestRestfulie < OdrkHTTPClientTestCase
  def setup
    super
    @client = Restfulie
  end

  def test_101_proxy
    flunk 'not supported'
  end

  def test_102_proxy_auth
    flunk 'not supported'
  end

  def test_103_keepalive
    flunk 'not supported'
  end

  def test_104_pipelining
    flunk 'not supported'
  end

  def test_105_ssl
    setup_sslserver
    assert_raise(Restfulie::Client::HTTP::Error::ServerNotAvailableError) do
      @client.at(@ssl_url + 'hello').get!
    end
    assert_equal(OpenSSL::SSL::SSLError, @client.at(@ssl_url + 'hello').get.class)
  end

  def test_106_ssl_ca
    setup_sslserver
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    ENV['SSL_CERT_DIR'] = ca_file
    begin
      @client.at(@ssl_url + 'hello').get!
    ensure
      ENV.delete('SSL_CERT_DIR')
    end
  end

  def test_107_ssl_hostname
    setup_sslserver
    ENV['SSL_CERT_DIR'] = File.expand_path('./fixture/', File.dirname(__FILE__))
    begin
      assert_raise(OpenSSL::SSL::SSLError) do
        @client.at(@ssl_fake_url + 'hello').get!
      end
    ensure
      ENV.delete('SSL_CERT_DIR')
    end
  end

  def test_108_basic_auth
    assert_equal('basic_auth OK', @client.at(url_with_auth(@url, 'admin', 'admin') + 'basic_auth').get!.body)
  end

  def test_109_digest_auth
    flunk 'not supported'
  end

  def test_201_get
    assert_equal('hello', @client.at(@url + 'hello').get!.body)
  end

  def test_202_post
    assert_equal('post,hello', @client.at(@url + 'servlet').with('Content-Type' => 'plain/text').post("hello").body)
  end

  def test_203_put
    assert_equal("put", @client.at(@url + 'servlet').with('Content-Type' => 'plain/text').put!('body').body)
    res = @client.at(@url + 'servlet').with('Content-Type' => 'application/x-www-form-urlencoded').put!("1=2&3=4")
    assert_equal('1=2&3=4', res.header["x-query"])
    # bytesize
    res = @client.at(@url + 'servlet').with('Content-Type' => 'application/x-www-form-urlencoded').put!('txt=あいうえお')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.header["x-query"])
    assert_equal('15', res.header["x-size"])
  end

  def test_204_delete
    assert_equal("delete", @client.at(@url + 'servlet').delete!.body)
  end

  def test_205_custom_method
    flunk 'not supported'
  end

  def test_206_response_header
    assert_match(/WEBrick/, @client.at(@url + 'hello').get!.headers['server'][0])
  end

  def test_207_cookies
    flunk 'not supported'
  end

  def test_208_redirect
    assert_equal('hello', @client.at(@url + 'redirect3').get!.body)
  end

  def test_209_redirect_loop_detection
    timeout(2) do
      @client.at(@url + 'redirect_self').get!.body
    end
  end

  def test_210_post_multipart
    flunk 'not supported'
  end

  def test_211_streaming_upload
    flunk 'not supported'
  end

  def test_212_streaming_download
    flunk 'not supported'
  end

  def test_213_gzip_get
    assert_equal('hello', @client.at(@url + 'compressed?enc=gzip').get.body)
    assert_equal('hello', @client.at(@url + 'compressed?enc=deflate').get.body)
  end

  def test_214_gzip_post
    assert_equal('hello', @client.at(@url + 'compressed').with('Content-Type' => 'application/x-www-form-urlencoded', 'Accept-Encoding' => 'gzip').post("enc=gzip").body)
    assert_equal('hello', @client.at(@url + 'compressed').with('Content-Type' => 'application/x-www-form-urlencoded', 'Accept-Encoding' => 'deflate').post("enc=deflate").body)
  end

  def test_215_charset
    body = @client.at(@url + 'charset').get!.body
    assert_equal(Encoding::EUC_JP, body.encoding)
    assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
  end
end

