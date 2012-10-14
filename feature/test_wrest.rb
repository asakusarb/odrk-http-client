# -*- encoding: utf-8 -*-
require 'wrest'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestWrest < OdrkHTTPClientTestCase
  def setup
    super
    Wrest.use_native! # use net/http
  end

  def test_101_proxy
    flunk 'not supported'
  end

  def test_102_proxy_auth
    flunk 'not supported'
  end

  def test_103_keepalive
    server = HTTPServer::KeepAliveServer.new($host)
    begin
      Wrest::Http::Session.new(server.url) do |s|
        5.times do
          assert_equal('12345', s.get('/').body)
        end
      end
    ensure
      server.close
    end
    # chunked
    server = HTTPServer::KeepAliveServer.new($host)
    begin
      Wrest::Http::Session.new(server.url) do |s|
        5.times do
          assert_equal('abcdefghijklmnopqrstuvwxyz1234567890abcdef', s.get('/chunked').body)
        end
      end
    ensure
      server.close
    end
  end

  def test_104_pipelining
    flunk 'not supported'
  end

  def test_105_ssl
    setup_sslserver
    assert_raise(OpenSSL::SSL::SSLError) do
      @ssl_url.to_uri.get
    end
  end

  def test_106_ssl_ca
    setup_sslserver
    ca_path = File.expand_path('./fixture/', File.dirname(__FILE__))
    assert_equal('hello ssl', (@ssl_url + 'hello').to_uri(:ca_path => ca_path).get.body)
  end

  def test_107_ssl_hostname
    setup_sslserver
    ca_path = File.expand_path('./fixture/', File.dirname(__FILE__))
    assert_raise(OpenSSL::SSL::SSLError) do
      (@ssl_fake_url + 'hello').to_uri(:ca_path => ca_path).get
    end
  end

  def test_108_basic_auth
    assert_equal('basic_auth OK', (@url + 'basic_auth').to_uri(:username => 'admin', :password => 'admin').get.body)
  end

  def test_109_digest_auth
    flunk('digest auth not supported')
  end

  def test_201_get
    assert_equal('hello', (@url + 'hello').to_uri.get.body)
  end

  def test_202_post
    assert_equal('hello', (@url + 'hello').to_uri.post('body').body)
  end

  def test_203_put
    assert_equal("put", (@url + 'servlet').to_uri.put.body)
    res = (@url + 'servlet').to_uri.put('1=2&3=4')
    assert_equal('1=2&3=4', res.headers["x-query"])
    # bytesize
    res = (@url + 'servlet').to_uri.put('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.headers["x-query"])
    assert_equal('15', res.headers["x-size"])
  end

  def test_204_delete
    assert_equal("delete", (@url + 'servlet').to_uri.delete.body)
  end

  def test_205_custom_method
    flunk 'custom method not supported'
  end

  def test_206_response_header
    assert_match(/WEBrick/, (@url + 'hello').to_uri.get.headers["server"])
  end

  def test_207_cookies
    flunk('Cookie is not supported')
  end

  def test_208_redirect
    assert_equal('hello', (@url + 'redirect3').to_uri.get.body)
  end

  def test_209_redirect_loop_detection
    assert_raise(Wrest::Exceptions::AutoRedirectLimitExceeded) do
      (@url + 'redirect_self').to_uri(:follow_redirects_limit => 10).get
    end
  end

  def test_2091_urlencoded
    assert_equal('1=2&3=4', (@url + 'servlet').to_uri.post('1' => '2', '3' => '4').headers[:x_query])
  end

  def test_210_post_multipart
    require 'wrest/multipart'
    File.open(__FILE__) do |file|
      res = (@url + 'servlet').to_uri.post_multipart(:upload => Wrest::Native::PostMultipart::UploadIO.new(file, 'text/plain'))
      assert_match(/FIND_TAG_IN_THIS_FILE/, res.body)
    end
  end

  def test_211_streaming_upload
    file = Tempfile.new(__FILE__)
    file << "*" * 4096 * 100
    file.close
    file.open
    req = Net::HTTP::Post.new(@url + 'chunked')
    req.body_stream = file
    # !! should be set by body_stream=
    req['Transfer-Encoding'] = 'chunked'
    res = @client.request(req)
    assert(res.header['x-count'].to_i >= 100)
    if filename = res.header['x-tmpfilename']
      File.unlink(filename)
    end
  end

  def test_212_streaming_download
    flunk('streaming download not supported')
  end

  def test_213_gzip_get
    assert_equal('hello', (@url + 'compressed?enc=gzip').to_uri.get.body)
    assert_equal('hello', (@url + 'compressed?enc=deflate').to_uri.get.body)
  end

  def test_214_gzip_post
    assert_equal('hello', (@url + 'compressed').to_uri.post('enc=gzip').body)
    assert_equal('hello', (@url + 'compressed').to_uri.post('enc=deflate').body)
  end

  def test_215_charset
    body = (@url + 'charset').to_uri.get.body
    assert_equal(Encoding::EUC_JP, body.encoding)
    assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
  end
end
