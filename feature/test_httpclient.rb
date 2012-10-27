# -*- encoding: utf-8 -*-
require 'httpclient'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestHTTPClient < OdrkHTTPClientTestCase
  # Make localhost a proxy target
  HTTPClient::NO_PROXY_HOSTS.clear

  def setup
    super
    @client = HTTPClient.new
    @client.debug_dev = STDERR if $DEBUG
  end

  def test_101_proxy
    setup_proxyserver
    @client.proxy = @proxy_url
    assert_equal('hello', @client.get(@url + 'hello').body)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_102_proxy_auth
    setup_proxyserver(true)
    @client.proxy = @proxy_url
    @client.set_proxy_auth('admin', 'admin')
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
    @client.ssl_config.set_trust_ca(ca_file)
    assert_equal('hello ssl', @client.get(@ssl_url + 'hello').body)
  end

  def test_107_ssl_hostname
    setup_sslserver
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    @client.ssl_config.set_trust_ca(ca_file)
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.get(@ssl_fake_url + 'hello')
    end
  end

  def test_1071_ssl_revocation
    setup_sslserver
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    crl1 = issue_crl([], cert('ca.pem'), key('ca.key', '1234'))
    crl21 = issue_crl([], cert('subca.pem'), key('subca.key', '1234'))
    crl22 = issue_crl([[cert('server.pem').serial, Time.now, 1]], cert('subca.pem'), key('subca.key', '1234'))
    # Not revoked
    @client.ssl_config.clear_cert_store
    @client.ssl_config.add_trust_ca(ca_file)
    @client.ssl_config.add_crl(crl1)
    @client.ssl_config.add_crl(crl21)
    assert_equal('hello ssl', @client.get(@ssl_url + 'hello').body)
    # Revoked
    @client.ssl_config.clear_cert_store
    @client.ssl_config.add_trust_ca(ca_file)
    @client.ssl_config.add_crl(crl1)
    @client.ssl_config.add_crl(crl22)
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.get(@ssl_url + 'hello')
    end
  end

  def test_108_basic_auth
    @client.set_auth(@url, 'admin', 'admin')
    assert_equal('basic_auth OK', @client.get(@url + 'basic_auth').body)
  end

  def test_109_digest_auth
    @client.set_auth(@url, 'admin', 'admin')
    assert_equal('digest_auth OK', @client.get(@url + 'digest_auth').body)
    # digest_sess
    @client.set_auth(@url, 'admin', 'admin')
    assert_equal('digest_sess_auth OK', @client.get(@url + 'digest_sess_auth').body)
  end

  def test_201_get
    assert_equal('hello', @client.get(@url + 'hello').body)
  end

  def test_202_post
    assert_equal('hello', @client.post(@url + 'hello', 'body').body)
  end

  def test_203_put
    assert_equal("put", @client.put(@url + 'servlet').body)
    res = @client.put(@url + 'servlet', {1=>2, 3=>4})
    assert_equal('1=2&3=4', res.header["x-query"][0])
    # bytesize
    res = @client.put(@url + 'servlet', 'txt' => 'あいうえお')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.header["x-query"][0])
    assert_equal('15', res.header["x-size"][0])
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
    res = @client.get(@url + 'cookies', :header => {'Cookie' => 'foo=0; bar=1'})
    assert_equal(2, @client.cookies.size)
    5.times do
      res = @client.get(@url + 'cookies')
    end
    assert_equal(2, @client.cookies.size)
    assert_equal('6', @client.cookies.find { |c| c.name == 'foo' }.value)
    assert_equal('7', @client.cookies.find { |c| c.name == 'bar' }.value)
  end

  def test_208_redirect
    assert_equal('hello', @client.get(@url + 'redirect3', :follow_redirect => true).body)
  end

  def test_209_redirect_loop_detection
    assert_raise(HTTPClient::BadResponseError) do
      @client.protocol_retry_count = 10
      @client.get(@url + 'redirect_self', :follow_redirect => true)
    end
  end

  def test_2091_urlencoded
    assert_equal('1=2&3=4', @client.post(@url + 'servlet', :body => {'1' => '2', '3' => '4'}).headers["X-Query"])
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
    @client.transparent_gzip_decompression = true
    assert_equal('hello', @client.get(@url + 'compressed?enc=gzip').body)
    assert_equal('hello', @client.get(@url + 'compressed?enc=deflate').body)
    @client.transparent_gzip_decompression = false
  end

  def test_214_gzip_post
    @client.transparent_gzip_decompression = true
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'gzip').body)
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'deflate').body)
    @client.transparent_gzip_decompression = false
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
