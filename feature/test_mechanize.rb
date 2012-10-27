# -*- encoding: utf-8 -*-
require 'mechanize'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestMechanize < OdrkHTTPClientTestCase
  def setup
    super
    @client = Mechanize.new
    @client.http.debug_output = STDERR if $DEBUG
  end

  def test_101_proxy
    setup_proxyserver
    proxy = URI.parse(@proxy_url)
    @client.set_proxy(proxy.host, proxy.port)
    assert_equal('hello', @client.get(@url + 'hello').body)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_102_proxy_auth
    setup_proxyserver(true)
    proxy = URI.parse(@proxy_url)
    @client.set_proxy(proxy.host, proxy.port, 'admin', 'admin')
    assert_equal('hello', @client.get(@url + 'hello').body)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_103_keepalive
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

  def test_104_pipelining
    flunk 'not supported'
  end

  def test_105_ssl
    setup_sslserver
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.get(@ssl_url + 'hello')
    end
  end

  def test_106_ssl_ca
    setup_sslserver
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    cert_store = OpenSSL::X509::Store.new
    cert_store.add_file(ca_file)
    @client.cert_store = cert_store
    assert_equal('hello ssl', @client.get(@ssl_url + 'hello').body)
  end

  def test_107_ssl_hostname
    setup_sslserver
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    cert_store = OpenSSL::X509::Store.new
    cert_store.add_file(ca_file)
    @client.cert_store = cert_store
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.get(@ssl_fake_url + 'hello')
    end
  end

  def test_108_basic_auth
    @client.auth('admin', 'admin')
    assert_equal('basic_auth OK', @client.get(@url + 'basic_auth').body)
  end

  def test_109_digest_auth
    @client.auth('admin', 'admin')
    assert_equal('digest_auth OK', @client.get(@url + 'digest_auth').body)
    # digest_sess
    @client.auth('admin', 'admin')
    assert_equal('digest_sess_auth OK', @client.get(@url + 'digest_sess_auth').body)
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
    flunk 'custom method not supported'
  end

  def test_206_response_header
    assert_match(/WEBrick/, @client.get(@url + 'hello').header['Server'])
  end

  def test_207_cookies
    res = @client.get(@url + 'cookies', [], nil, {'Cookie' => 'foo=0; bar=1'})
    assert_equal(2, @client.cookies.size)
    5.times do
      res = @client.get(@url + 'cookies')
    end
    assert_equal(2, @client.cookies.size)
    assert_equal('6', @client.cookies.find { |c| c.name == 'foo' }.value)
    assert_equal('7', @client.cookies.find { |c| c.name == 'bar' }.value)
  end

  def test_208_redirect
    assert_equal('hello', @client.get(@url + 'redirect3').body)
  end

  def test_209_redirect_loop_detection
    assert_raise(Mechanize::RedirectLimitReachedError) do
      @client.get(@url + 'redirect_self').body
    end
  end

  def test_2091_urlencoded
    assert_equal('1=2&3=4', @client.post(@url + 'servlet', {'1' => '2', '3' => '4'}).header["X-Query"])
  end

  def test_210_post_multipart
    File.open(__FILE__) do |file|
      res = @client.post(@url + 'servlet', :upload => file)
      assert_match(/FIND_TAG_IN_THIS_FILE/, res.body)
    end
  end

  def test_211_streaming_upload
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

  def test_212_streaming_download
    flunk 'not supported'
  end

  def test_213_gzip_get
    assert_equal('hello', @client.get(@url + 'compressed?enc=gzip').body)
    assert_equal('hello', @client.get(@url + 'compressed?enc=deflate').body)
  end

  def test_214_gzip_post
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'gzip').body)
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'deflate').body)
  end

  def test_215_charset
    body = @client.get(@url + 'charset').body
    assert_equal(Encoding::EUC_JP, body.encoding)
    assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
  end

  def test_216_iri
    server = HTTPServer::IRIServer.new($host)
    assert_equal('hello', @client.get(server.url + 'hello?q=grebe-camilla-träff-åsa-norlen-paul').body)
    server.close
  end
end
