# -*- encoding: utf-8 -*-
require 'patron'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestPatron < OdrkHTTPClientTestCase
  def setup
    super
    url = URI.parse(@url)
    @client = Patron::Session.new
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

  def test_104_pipelining
    flunk 'not supported'
  end

  def test_105_ssl
    setup_sslserver
    client = Patron::Session.new
    assert_raise(Patron::Error) do
      client.get(@ssl_url + 'hello')
    end
  end

  def test_106_ssl_ca
    setup_sslserver
    client = Patron::Session.new
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    flunk 'cannot configure CAfile'
  end

  def test_107_ssl_hostname
    setup_sslserver
    client = Patron::Session.new
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    # !! cannot configure CAfile
    assert_raise(Patron::Error) do
      client.get(@ssl_fake_url + 'hello')
    end
  end

  def test_108_basic_auth
    @client.username = 'admin'
    @client.password = 'admin'
    @client.auth_type = :basic
    assert_equal('basic_auth OK', @client.get(@url + 'basic_auth').body)
  end

  def test_109_digest_auth
    @client.username = 'admin'
    @client.password = 'admin'
    @client.auth_type = :digest
    assert_equal('digest_auth OK', @client.get(@url + 'digest_auth').body)
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
    # !! case sensitive
    assert_equal('1=2&3=4', res.headers["X-Query"])
    # bytesize
    res = @client.put(@url + 'servlet', 'txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.headers["X-Query"])
    assert_equal('15', res.headers["X-Size"])
  end

  def test_204_delete
    assert_equal("delete", @client.delete(@url + 'servlet').body)
  end

  def test_205_custom_method
    flunk 'custom method not supported'
  end

  def test_206_response_header
    assert_match(/WEBrick/, @client.get(@url + 'hello').headers['Server'])
  end

  def test_207_cookies
    @client.handle_cookies
    res = @client.get(@url + 'cookies', 'Cookie' => 'foo=0; bar=1 ')
    assert_equal(2, res.headers['Set-Cookie'].size)
    res.headers['Set-Cookie'].find { |c| /foo=(\d)/ =~ c }
    assert_equal('1', $1)
    res.headers['Set-Cookie'].find { |c| /bar=(\d)/ =~ c }
    assert_equal('2', $1)
    5.times do
      res = @client.get(@url + 'cookies')
    end
    assert_equal(2, res.headers['Set-Cookie'].size)
    res.headers['Set-Cookie'].find { |c| /foo=(\d)/ =~ c }
    assert_equal('6', $1)
    res.headers['Set-Cookie'].find { |c| /bar=(\d)/ =~ c }
    assert_equal('7', $1)
  end

  def test_208_redirect
    assert_equal('hello', @client.get(@url + 'redirect3').body)
  end

  def test_209_redirect_loop_detection
    assert_raise(Patron::TooManyRedirects) do
      @client.get(@url + 'redirect_self').body
    end
  end

  def test_2091_urlencoded
    assert_equal('1=2&3=4', @client.post(@url + 'servlet', {'1' => '2', '3' => '4'}).headers["X-Query"])
  end

  def test_210_post_multipart
    res = @client.post_multipart(@url + 'servlet', {}, {:upload => __FILE__})
    assert_match(/FIND_TAG_IN_THIS_FILE/, res.body)
  end

  def test_211_streaming_upload
    file = Tempfile.new(__FILE__)
    file << "*" * 4096 * 100
    file.close
    file.open
    res = @client.request(:post, @url + 'chunked', {}, :file => file.path)
    # !! case sensitive
    assert(res.headers['X-Count'].to_i >= 26)
    if filename = res.headers['X-Tmpfilename']
      File.unlink(filename)
    end
  end

  def test_212_streaming_download
    file = Tempfile.new('download')
    begin
      @client.get_file(@url + 'largebody', file.path)
      assert_equal(10000000, File.read(file.path).size)
    ensure
      file.unlink
    end
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
end
