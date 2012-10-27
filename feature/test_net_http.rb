# -*- encoding: utf-8 -*-
require 'net/https'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestNetHTTP < OdrkHTTPClientTestCase
  def setup
    super
    url = URI.parse(@url)
    @client = Net::HTTP.new(url.host, url.port)
    @client.set_debug_output(STDERR) if $DEBUG
  end

  def test_101_proxy
    setup_proxyserver
    url = URI.parse(@url)
    proxy = URI.parse(@proxy_url)
    client = Net::HTTP::Proxy(proxy.host, proxy.port).new(url.host, url.port)
    assert_equal('hello', client.get(url.path + 'hello').body)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_102_proxy_auth
    setup_proxyserver(true)
    url = URI.parse(@url)
    proxy = URI.parse(@proxy_url)
    client = Net::HTTP::Proxy(proxy.host, proxy.port, 'admin', 'admin').new(url.host, url.port)
    assert_equal('hello', client.get(url.path + 'hello').body)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_103_keepalive
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

  def test_104_pipelining
    flunk 'not supported'
  end

  def test_105_ssl
    setup_sslserver
    @client = Net::HTTP.new('localhost', $ssl_port)
    @client.use_ssl = true
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.get(@ssl_url + 'hello')
    end
  end

  def test_106_ssl_ca
    setup_sslserver
    @client = Net::HTTP.new('localhost', $ssl_port)
    @client.use_ssl = true
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    @client.ca_file = ca_file
    assert_equal('hello ssl', @client.get(@ssl_url + 'hello').body)
  end

  def test_107_ssl_hostname
    setup_sslserver
    @client = Net::HTTP.new('127.0.0.1', $ssl_port)
    @client.use_ssl = true
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    @client.ca_file = ca_file
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.get(@ssl_fake_url + 'hello')
    end
  end

  def test_108_basic_auth
    req = Net::HTTP::Get.new(@url + 'basic_auth')
    req.basic_auth('admin', 'admin')
    assert_equal('basic_auth OK', @client.request(req).body)
  end

  def test_109_digest_auth
    flunk 'digest auth not supported'
    flunk 'digest-sess auth not supported'
  end

  def test_201_get
    assert_equal('hello', @client.get(@url + 'hello').body)
  end

  def test_202_post
    assert_equal('hello', @client.post(@url + 'hello', 'body').body)
  end

  def test_203_put
    assert_equal("put", @client.put(@url + 'servlet', '').body)
    res = @client.put(@url + 'servlet', '1=2&3=4')
    assert_equal('1=2&3=4', res.header["x-query"])
    # bytesize
    res = @client.put(@url + 'servlet', 'txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.header["x-query"])
    assert_equal('15', res.header["x-size"])
  end

  def test_204_delete
    assert_equal("delete", @client.delete(@url + 'servlet').body)
  end

  def test_205_custom_method
    flunk 'custom method not directly supported'
  end

  def test_206_response_header
    assert_match(/WEBrick/, @client.get(@url + 'hello').header['Server'])
  end

  def test_207_cookies
    flunk 'not supported'
  end

  def test_208_redirect
    assert_equal('hello', @client.get(@url + 'redirect3'))
  end

  def test_209_redirect_loop_detection
    assert_raise(RuntimeError) do
      @client.get(@url + 'redirect_self')
    end
  end

  def test_2091_urlencoded
    assert_equal('1=2&3=4', @client.post(@url + 'hello', {'1' => '2', '3' => '4'}).header["x-query"])
  end

  def test_210_post_multipart
    File.open(__FILE__) do |file|
      req = Net::HTTP::Post.new(@url + 'servlet')
      req.set_form({'upload' => file}, 'multipart/form-data')
      res = @client.request(req)
      content = res.body
      assert_match(/FIND_TAG_IN_THIS_FILE/, content)
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
    assert(res.header['x-count'].to_i >= 25)
    if filename = res.header['x-tmpfilename']
      File.unlink(filename)
    end
  end

  def test_212_streaming_download
    c = 0
    @client.get(@url + 'largebody') do |str|
      c += 1
    end
    assert(c > 600)
  end

  def test_213_gzip_get
    assert_equal('hello', @client.get(@url + 'compressed?enc=gzip').body)
    assert_equal('hello', @client.get(@url + 'compressed?enc=deflate').body)
  end

  def test_214_gzip_post
    assert_equal('hello', @client.post(@url + 'compressed', 'enc=gzip', 'Accept-Encoding' => 'gzip').body)
    assert_equal('hello', @client.post(@url + 'compressed', 'enc=deflate', 'Accept-Encoding' => 'deflate').body)
  end

  def test_215_charset
    body = @client.get(@url + 'charset').body
    assert_equal(Encoding::EUC_JP, body.encoding)
    assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
  end

  def test_216_iri
    server = HTTPServer::IRIServer.new($host)
    require 'addressable/uri'
    assert_equal('hello', Net::HTTP.get(Addressable::URI.parse(server.url + 'hello?q=grebe-camilla-träff-åsa-norlen-paul')))
    server.close
  end
end
