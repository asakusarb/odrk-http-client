# -*- encoding: utf-8 -*-
require 'open-uri'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestOpenURI < OdrkHTTPClientTestCase
  def test_101_proxy
    setup_proxyserver
    assert_equal('hello', open(@url + 'hello', :proxy => @proxy_url) { |f| f.read })
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_102_proxy_auth
    setup_proxyserver(true)
    assert_equal('hello', open(@url + 'hello', :proxy_http_basic_authentication => [@proxy_url, 'admin', 'admin']) { |f| f.read })
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_103_keepalive
    flunk 'not supported'
  end

  def test_104_pipelining
    flunk 'not supported'
  end

  def test_105_ssl
    setup_sslserver
    assert_raise(OpenSSL::SSL::SSLError) do
      open(@ssl_url + 'hello') { |f| f.read }
    end
  end

  def test_106_ssl_ca
    setup_sslserver
    ca_path = File.expand_path('./fixture/', File.dirname(__FILE__))
    assert_equal('hello ssl', open(@ssl_url + 'hello', :ssl_ca_cert => ca_path) { |f| f.read })
  end

  def test_107_ssl_hostname
    setup_sslserver
    ca_path = File.expand_path('./fixture/', File.dirname(__FILE__))
    assert_raise(OpenSSL::SSL::SSLError) do
      open(@ssl_fake_url + 'hello', :ssl_ca_cert => ca_path) { |f| f.read }
    end
  end

  def test_108_basic_auth
    body = open(@url + 'basic_auth', :http_basic_authentication => ['admin', 'admin']) { |f| f.read }
    assert_equal('basic_auth OK', body)
  end

  def test_109_digest_auth
    flunk 'digest auth not supported'
    flunk 'digest-sess auth not supported'
  end

  def test_201_get
    assert_equal('hello', open(@url + 'hello') { |f| f.read })
  end

  def test_202_post
    flunk 'not supported'
  end

  def test_203_put
    flunk 'not supported'
  end

  def test_204_delete
    flunk 'not supported'
  end

  def test_205_custom_method
    flunk 'not supported'
  end

  def test_206_response_header
    open(@url + 'hello') { |f|
      assert_match(/WEBrick/, f.meta['server'])
    }
  end

  def test_207_cookies
    flunk 'not supported'
  end

  def test_208_redirect
    body = open(@url + 'redirect3') { |f| f.read }
    assert_equal('hello', body)
  end

  def test_209_redirect_loop_detection
    assert_raise(RuntimeError) do
      open(@url + 'redirect_self') { |f| f.read }
    end
  end

  def test_210_post_multipart
    flunk 'not supported'
  end

  def test_211_streaming_upload
    flunk 'not supported'
  end

  def test_212_streaming_download
    c = 0
    open(@url + 'largebody') do |f|
      while f.read(16384)
        c += 1
      end
    end
    assert(c > 600)
  end

  def test_213_gzip_get
    assert_equal('hello', open(@url + 'compressed?enc=gzip') { |f| f.read })
    assert_equal('hello', open(@url + 'compressed?enc=deflate') { |f| f.read })
  end

  def test_214_gzip_post
    raise 'non-GET methods are not supported'
  end

  def test_215_charset
    body = open(@url + 'charset') { |f| f.read }
    assert_equal(Encoding::EUC_JP, body.encoding)
    assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
  end
end

