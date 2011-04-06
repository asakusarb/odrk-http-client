# -*- encoding: utf-8 -*-
require 'net/http'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestNetHTTP < OdrkHTTPClientTestCase
  def setup
    super
    url = URI.parse($url)
    @client = Net::HTTP.new(url.host, url.port)
    @client.set_debug_output(STDERR) if $DEBUG
  end

  def test_ssl
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    @client = Net::HTTP.new('localhost', $ssl_port)
    @client.use_ssl = true
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.get(ssl_url + 'hello')
    end
  end

  def test_ssl_ca
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    @client = Net::HTTP.new('localhost', $ssl_port)
    @client.use_ssl = true
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    @client.ca_file = ca_file
    assert_equal('hello ssl', @client.get(ssl_url + 'hello').body)
  end

  def test_ssl_hostname
    setup_sslserver
    ssl_url = "https://127.0.0.1:#{$ssl_port}/"
    @client = Net::HTTP.new('127.0.0.1', $ssl_port)
    @client.use_ssl = true
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    @client.ca_file = ca_file
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.get(ssl_url + 'hello')
    end
  end

  def test_gzip_get
    assert_equal('hello', @client.get(@url + 'compressed?enc=gzip').body)
    assert_equal('hello', @client.get(@url + 'compressed?enc=deflate').body)
  end

  def test_gzip_post
    assert_equal('hello', @client.post(@url + 'compressed', 'enc=gzip').body)
    assert_equal('hello', @client.post(@url + 'compressed', 'enc=deflate').body)
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

  def test_post_multipart
    File.open(__FILE__) do |file|
      req = Net::HTTP::Post.new(@url + 'servlet')
      req.set_form({'upload' => file}, 'multipart/form-data')
      res = @client.request(req)
      content = res.body
      assert_match(/FIND_TAG_IN_THIS_FILE/, content)
    end
  end

  def test_basic_auth
    req = Net::HTTP::Get.new(@url + 'basic_auth')
    req.basic_auth('admin', 'admin')
    assert_equal('basic_auth OK', @client.request(req).body)
  end

  def test_digest_auth
    flunk 'digest auth not supported'
    flunk 'digest-sess auth not supported'
  end

  def test_redirect
    assert_equal('hello', @client.get(@url + 'redirect3'))
  end

  def test_redirect_loop_detection
    assert_raise(RuntimeError) do
      @client.get(@url + 'redirect_self')
    end
  end

  def test_keepalive
    server = HTTPServer::KeepAliveServer.new($host)
    url = URI.parse(server.url)
    c = Net::HTTP.new(url.host, url.port)
    c.start
    begin
      5.times do
        assert_equal('12345', c.get(url.path).body)
      end
    ensure
      c.finish
      server.close
    end
    # chunked
    server = HTTPServer::KeepAliveServer.new($host)
    url = URI.parse(server.url)
    c = Net::HTTP.new(url.host, url.port)
    c.start
    begin
      5.times do
        assert_equal('abcdefghijklmnopqrstuvwxyz1234567890abcdef', c.get(url.path + 'chunked').body)
      end
    ensure
      c.finish
      server.close
    end
  end

  def test_streaming_upload
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

  def test_streaming_download
    c = 0
    @client.get(@url + 'largebody') do |str|
      c += 1
    end
    assert(c > 600)
  end

  if RUBY_VERSION > "1.9"
    def test_charset
      body = @client.get(@url + 'charset').body
      assert_equal(Encoding::EUC_JP, body.encoding)
      assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
    end
  end
end
