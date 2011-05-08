# -*- encoding: utf-8 -*-
require 'faraday'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestFaraday < OdrkHTTPClientTestCase
  def setup
    super
    url = URI.parse($url)
    @client = Faraday.new(:url => (url + "/").to_s) { |builder|
      builder.adapter :typhoeus
    }
    @url = url.path
  end

  def setup_nethttp_client(opt = {})
    url = URI.parse($url)
    @client = Faraday.new(opt.merge(:url => (url + "/").to_s)) { |builder|
      builder.adapter :net_http
    }
  end

  def test_ssl
    setup_sslserver
    setup_nethttp_client
    ssl_url = "https://localhost:#{$ssl_port}/"
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.get(ssl_url + 'hello')
    end
  end

  def test_ssl_ca
    setup_sslserver
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    setup_nethttp_client(:ssl => {:ca_file => ca_file})
    ssl_url = "https://localhost:#{$ssl_port}/"
    assert_equal('hello ssl', @client.get(ssl_url + 'hello').body)
  end

  def test_ssl_hostname
    setup_sslserver
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    setup_nethttp_client(:ssl => {:ca_file => ca_file})
    ssl_url = "https://127.0.0.1:#{$ssl_port}/"
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
    assert_equal("put", @client.put(@url + 'servlet').body)
    res = @client.put(@url + 'servlet', '1=2&3=4')
    assert_equal('1=2&3=4', res.headers["x-query"])
    # bytesize
    res = @client.put(@url + 'servlet', 'txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_equal('txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A', res.headers["x-query"])
    assert_equal('15', res.headers["x-size"])
  end

  def test_delete
    assert_equal("delete", @client.delete(@url + 'servlet').body)
  end

  def test_custom_method
    flunk 'custom method not supported'
  end

  def test_cookies
    flunk('Cookie not supported')
    res = @client.get(@url + 'cookies', :header => {'Cookie' => 'foo=0; bar=1'})
    assert_equal(2, res.cookies.size)
    5.times do
      res = @client.get(@url + 'cookies')
    end
    assert_equal(2, res.cookies.size)
    assert_equal('6', res.cookies.find { |c| c.name == 'foo' }.value)
    assert_equal('7', res.cookies.find { |c| c.name == 'bar' }.value)
  end

  def test_post_multipart
    url = URI.parse($url)
    @client = Faraday.new(:url => (url + "/").to_s) { |builder|
      builder.request :multipart
      builder.adapter :net_http
    }
    res = @client.post(@url + 'servlet', :upload => Faraday::UploadIO.new(__FILE__, 'text/plain'))
    assert_match(/FIND_TAG_IN_THIS_FILE/, res.body)
    #
    @client = Faraday.new(:url => (url + "/").to_s) { |builder|
      builder.request :multipart
      builder.adapter :typhoeus
    }
    res = @client.post(@url + 'servlet', :upload => Faraday::UploadIO.new(__FILE__, 'text/plain'))
    assert_match(/FIND_TAG_IN_THIS_FILE/, res.body)
  end

  def test_basic_auth
    @client.basic_auth('admin', 'admin')
    assert_equal('basic_auth OK', @client.get(@url + 'basic_auth').body)
  end

  def test_digest_auth
    flunk('digest auth is not supported')
  end

  def test_redirect
    assert_equal('hello', @client.get(@url + 'redirect3').body)
  end

  def test_redirect_loop_detection
    assert_raise(RuntimeError) do
      @client.get(@url + 'redirect_self')
    end
  end

  def test_keepalive
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

  def test_streaming_upload
    file = Tempfile.new(__FILE__)
    file << "*" * 4096 * 100
    file.close
    file.open
    setup_nethttp_client
    res = @client.put(@url + 'chunked', file)
    assert(res.header['x-count'][0].to_i >= 100)
    if filename = res.header['x-tmpfilename'][0]
      File.unlink(filename)
    end
  end

  def test_streaming_download
    flunk('streaming download not supported')
  end

  if RUBY_VERSION > "1.9"
    def test_charset
      body = @client.get(@url + 'charset').body
      assert_equal(Encoding::EUC_JP, body.encoding)
      assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
    end
  end
end
