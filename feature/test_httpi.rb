# -*- encoding: utf-8 -*-
require 'httpi'
require File.expand_path('./test_setting', File.dirname(__FILE__))

# for adapter
require 'httpclient'
HTTPClient::NO_PROXY_HOSTS.clear

class TestHTTPI < OdrkHTTPClientTestCase
  def setup
    super
    @client = HTTPI
  end

  def req(url)
    HTTPI::Request.new(url)
  end

  def test_101_proxy
    setup_proxyserver
    req = req(@url + 'hello')
    req.proxy = @proxy_url
    assert_equal('hello', @client.get(req).body)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_102_proxy_auth
    flunk 'not supported'
  end

  def test_103_keepalive
  timeout(2) do
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
  end

  def test_104_pipelining
    flunk 'not supported'
  end

  def test_105_ssl
    setup_sslserver
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.post(@ssl_url + 'hello')
    end
  end

  def test_106_ssl_ca
    setup_sslserver
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    req = req(@ssl_url + 'hello')
    req.auth.ssl.ca_cert_file = ca_file
    res = @client.get(req)
    assert_equal('hello ssl', res.body)
  end

  def test_107_ssl_hostname
    setup_sslserver
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    req = req(@ssl_fake_url + 'hello')
    req.auth.ssl.ca_cert_file = ca_file
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.get(req)
    end
  end

  def test_108_basic_auth
    assert_equal('basic_auth OK', @client.get(url_with_auth(@url + 'basic_auth', 'admin', 'admin')).body)
  end

  def test_109_digest_auth
    assert_equal('digest_auth OK', @client.get(url_with_auth(@url + 'digest_auth', 'admin', 'admin')).body)
    # digest_sess
    assert_equal('digest_sess_auth OK', @client.get(url_with_auth(@url + 'digest_sess_auth', 'admin', 'admin')).body)
  end

  def test_201_get
    assert_equal('hello', @client.get(@url + 'hello').body)
  end

  def test_202_post
    assert_equal('hello', @client.post(@url + 'hello', 'body').body)
  end

  def test_203_put
    assert_equal("put", @client.put(@url + 'servlet').body)
    res = @client.put(@url + 'servlet', '1=2&3=4')
    assert_equal('1=2&3=4', res.headers["x-query"])
    # bytesize
    res = @client.put(@url + 'servlet', 'txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.headers["x-query"])
    assert_equal('15', res.headers["x-size"])
  end

  def test_204_delete
    assert_equal("delete", @client.delete(@url + 'servlet').body)
  end

  def test_205_custom_method
    res = @client.request(:custom, @url + 'servlet', :query => {1=>2, 3=>4}, :body => 'custom?')
    assert_equal('custom?', res.body)
    assert_equal('1=2&3=4', res.headers["X-Query"])
  end

  def test_206_response_header
    assert_match(/WEBrick/, @client.get(@url + 'hello').headers['Server'])
  end

  def test_207_cookies
    req = req(@url + 'cookies')
    req.headers['Cookie'] = 'foo=0; bar=1'
    res = @client.get(req)
    assert_equal(2, res.cookies.size)
    5.times do
      res = @client.get(@url + 'cookies')
    end
    assert_equal(2, res.cookies.size)
    assert_equal('6', res.cookies.find { |c| c.name == 'foo' }.value)
    assert_equal('7', res.cookies.find { |c| c.name == 'bar' }.value)
  end

  def test_208_redirect
    assert_equal('hello', @client.get(@url + 'redirect3').body)
  end

  def test_209_redirect_loop_detection
    assert_raise(RuntimeError) do
      @client.get(@url + 'redirect_self')
    end
  end

  def test_2091_urlencoded
    assert_equal('1=2&3=4', @client.post(@url + 'servlet', {'1' => '2', '3' => '4'}).headers["X-Query"])
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
    assert(res.header['x-count'][0].to_i >= 7)
    if filename = res.header['x-tmpfilename'][0]
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
    req = req(@url + 'compressed?enc=gzip')
    req.headers['Accept-Encoding'] = 'gzip'
    assert_equal('hello', @client.get(req).body)
    #
    req = req(@url + 'compressed?enc=deflate')
    req.headers['Accept-Encoding'] = 'deflate'
    assert_equal('hello', @client.get(req).body)
  end

  def test_214_gzip_post
    req = req(@url + 'compressed?enc=gzip')
    req.body = {:enc => 'gzip'}
    req.headers['Accept-Encoding'] = 'gzip'
    assert_equal('hello', @client.post(req).body)
    #
    req = req(@url + 'compressed?enc=deflate')
    req.body = {:enc => 'deflate'}
    req.headers['Accept-Encoding'] = 'deflate'
    assert_equal('hello', @client.post(req).body)
  end

  def test_215_charset
    body = @client.get(@url + 'charset').body
    assert_equal(Encoding::EUC_JP, body.encoding)
    assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
  end

  def test_216_iri
    require 'addressable/uri'
    server = HTTPServer::IRIServer.new($host)
    assert_equal('hello', @client.get(server.url + 'hello?q=grebe-camilla-träff-åsa-norlen-paul').body)
    server.close
  end
end
