# -*- encoding: utf-8 -*-
require 'restclient'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestRestClient < OdrkHTTPClientTestCase
  def setup
    super
    @client = RestClient
  end

  def teardown
    super
    # Proxy is a process wide configuration...
    @client.proxy = nil
  end

  def test_101_proxy
    setup_proxyserver
    @client.proxy = @proxy_url
    assert_equal('hello', @client.get(@url + 'hello').body)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_102_proxy_auth
    setup_proxyserver(true)
    @client.proxy = url_with_auth(@proxy_url, 'admin', 'admin')
    assert_equal('hello', @client.get(@url + 'hello').body)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_103_keepalive
  timeout(2) do
    server = HTTPServer::KeepAliveServer.new($host)
    begin
      5.times do
        assert_equal('12345', @client.get(server.url).body)
      end
    ensure
      server.close
    end
    # chunked
    server = HTTPServer::KeepAliveServer.new($host)
    begin
      5.times do
        assert_equal('abcdefghijklmnopqrstuvwxyz1234567890abcdef', @client.get(server.url + 'chunked').body)
      end
    ensure
      server.close
    end
  end
  end

  def test_104_pipelining
    flunk 'not supported'
  end

  def test_105_ssl
    setup_sslserver
    client = RestClient::Request.new(:method => :get, :url => @ssl_url + 'hello')
    assert_raise(OpenSSL::SSL::SSLError) do
      client.execute
    end
  end

  def test_106_ssl_ca
    setup_sslserver
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    client = RestClient::Request.new(:method => :get, :url => @ssl_url + 'hello', :verify_ssl => OpenSSL::SSL::VERIFY_PEER, :ssl_ca_file => ca_file)
    assert_equal('hello ssl', client.execute.body)
  end

  def test_107_ssl_hostname
    setup_sslserver
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    client = RestClient::Request.new(:method => :get, :url => @ssl_fake_url + 'hello', :verify_ssl => OpenSSL::SSL::VERIFY_PEER, :ssl_ca_file => ca_file)
    assert_raise(OpenSSL::SSL::SSLError) do
      client.execute
    end
  end

  def test_108_basic_auth
    resource = RestClient::Resource.new(@url + 'basic_auth', :user => 'admin', :password => 'admin')
    assert_equal('basic_auth OK', resource.get.body)
    # you can use http://user:pass@host/path style, too.
  end

  def test_109_digest_auth
    flunk 'digest auth is not supported'
    flunk 'digest-sess auth is not supported'
  end

  def test_201_get
    assert_equal('hello', @client.get(@url + 'hello').body)
  end

  def test_202_post
    assert_equal('hello', @client.post(@url + 'hello', 'body').body)
  end

  def test_203_put
    assert_equal("put", @client.put(@url + 'servlet', ''))
    res = @client.put(@url + 'servlet', '1=2&3=4')
    assert_equal('1=2&3=4', res.headers[:x_query])
    # bytesize
    res = @client.put(@url + 'servlet', 'txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.headers[:x_query])
    assert_equal('15', res.headers[:x_size])
  end

  def test_204_delete
    assert_equal("delete", @client.delete(@url + 'servlet'))
  end

  def test_205_custom_method
    flunk 'custom method not directly supported'
  end

  def test_206_response_header
    assert_match(/WEBrick/, @client.get(@url + 'hello').headers[:server])
  end

  def test_207_cookies
    res = @client.get(@url + 'cookies', :cookies => {:foo => '0', :bar => '1'})
    # It returns 3. It looks fail to parse expiry date. 'Expires' => 'Sun'
    assert_equal(2, res.cookies.size, res.cookies.inspect)
    5.times do
      # restclient doesn't send cookies automatically
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
    timeout(2) do
      assert_raise(RestClient::MaxRedirectsReached) do
        @client.get(@url + 'redirect_self').body
      end
    end
  end

  def test_2091_urlencoded
    assert_equal('1=2&3=4', @client.post(@url + 'servlet', {'1' => '2', '3' => '4'}).headers[:x_query])
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
    # !! response header Hash keys are Symbols
    assert(res.headers[:x_count].to_i >= 7)
    if filename = res.headers[:x_tmpfilename]
      File.unlink(filename)
    end
  end

  def test_212_streaming_download
    flunk('streaming download not supported')
  end

  def test_213_gzip_get
    assert_equal('hello', @client.get(@url + 'compressed?enc=gzip'))
    assert_equal('hello', @client.get(@url + 'compressed?enc=deflate'))
  end

  def test_214_gzip_post
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'gzip'))
    assert_equal('hello', @client.post(@url + 'compressed', :enc => 'deflate'))
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

