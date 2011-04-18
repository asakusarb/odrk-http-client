# -*- encoding: utf-8 -*-
require 'mechanize'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestMechanize < OdrkHTTPClientTestCase
  def setup
    super
    @client = Mechanize.new
    @client.http.debug_output = STDERR if $DEBUG
  end

  def test_ssl
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.get(ssl_url + 'hello')
    end
  end

  def test_ssl_ca
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    @client.http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    # !! @client.ca_file is ignored?
    @client.http.ca_file = ca_file
    assert_equal('hello ssl', @client.get(ssl_url + 'hello').body)
  end

  def test_ssl_hostname
    setup_sslserver
    ssl_url = "https://127.0.0.1:#{$ssl_port}/"
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    @client.ca_file = ca_file
    @client.http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.get(ssl_url + 'hello')
    end
  end

  def test_gzip_get
    assert_equal('hello', @client.get(@url + 'compressed?enc=gzip').body)
    assert_equal('hello', @client.get(@url + 'compressed?enc=deflate').body)
  end

  def test_gzip_post
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'gzip').body)
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'deflate').body)
  end

  def test_put
    assert_equal("put", @client.put(@url + 'servlet', '').body)
    res = @client.put(@url + 'servlet', '1=2&3=4')
    assert_equal('1=2&3=4', res.header["x-query"])
    # bytesize
    res = @client.put(@url + 'servlet', 'txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.header["x-query"])
    assert_equal('15', res.header["x-size"])
  end

  def test_delete
    assert_equal("delete", @client.delete(@url + 'servlet').body)
  end

  def test_custom_method
    flunk 'custom method not supported'
  end

  def test_cookies
    res = @client.get(@url + 'cookies', [], nil, {'Cookie' => 'foo=0; bar=1'})
    assert_equal(2, @client.cookies.size)
    5.times do
      res = @client.get(@url + 'cookies')
    end
    assert_equal(2, @client.cookies.size)
    assert_equal('6', @client.cookies.find { |c| c.name == 'foo' }.value)
    assert_equal('7', @client.cookies.find { |c| c.name == 'bar' }.value)
  end

  def test_post_multipart
    File.open(__FILE__) do |file|
      res = @client.post(@url + 'servlet', :upload => file)
      assert_match(/FIND_TAG_IN_THIS_FILE/, res.body)
    end
  end

  def test_basic_auth
    @client.auth('admin', 'admin')
    assert_equal('basic_auth OK', @client.get(@url + 'basic_auth').body)
  end

  def test_digest_auth
    @client.auth('admin', 'admin')
    assert_equal('digest_auth OK', @client.get(@url + 'digest_auth').body)
    # digest_sess
    @client.auth('admin', 'admin')
    assert_equal('digest_sess_auth OK', @client.get(@url + 'digest_sess_auth').body)
  end

  def test_redirect
    assert_equal('hello', @client.get(@url + 'redirect3').body)
  end

  def test_redirect_loop_detection
    assert_raise(Mechanize::RedirectLimitReachedError) do
      @client.get(@url + 'redirect_self').body
    end
  end

  def test_keepalive
    server = HTTPServer::KeepAliveServer.new($host)
    5.times do
      assert_equal('12345', @client.get(server.url).body)
    end
    server.close
    # chunked
    server = HTTPServer::KeepAliveServer.new($host)
    5.times do
      assert_equal('abcdefghijklmnopqrstuvwxyz1234567890abcdef', @client.get(server.url + 'chunked').body)
    end
    server.close
  end

  def test_streaming_upload
    file = Tempfile.new(__FILE__)
    file << "*" * 4096 * 100
    file.close
    file.open
    res = @client.post(@url + 'chunked', file)
    assert(res.header['x-count'].to_i >= 10)
    if filename = res.header['x-tmpfilename']
      File.unlink(filename)
    end
  end

  def test_streaming_download
    flunk 'not supported'
  end

  if RUBY_VERSION > "1.9"
    def test_charset
      body = @client.get(@url + 'charset').body
      assert_equal(Encoding::EUC_JP, body.encoding)
      assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
    end
  end
end
