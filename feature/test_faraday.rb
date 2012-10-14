# -*- encoding: utf-8 -*-
require 'faraday'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestFaraday < OdrkHTTPClientTestCase
  def setup
    super
    @client = Faraday.new { |builder|
      builder.adapter :net_http
    }
  end

  def test_101_proxy
    setup_proxyserver
    client = Faraday.new(:proxy => @proxy_url) { |builder|
      builder.adapter :net_http
    }
    assert_equal('hello', client.get(@url + '/hello').body)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_102_proxy_auth
    setup_proxyserver(true)
    client = Faraday.new(:proxy => {:uri => @proxy_url, :user => 'admin', :password => 'admin' }) { |builder|
      builder.adapter :net_http
    }
    assert_equal('hello', client.get(@url + 'hello').body)
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
    assert_raise(Faraday::Error::ConnectionFailed) do
      @client.get(@ssl_url + 'hello')
    end
  end

  def test_106_ssl_ca
    setup_sslserver
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    client = Faraday.new(:ssl => {:ca_file => ca_file}) { |builder|
      builder.adapter :net_http
    }
    assert_equal('hello ssl', client.get(@ssl_url + 'hello').body)
  end

  def test_107_ssl_hostname
    setup_sslserver
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    client = Faraday.new(:ssl => {:ca_file => ca_file}) { |builder|
      builder.adapter :net_http
    }
    assert_raise(Faraday::Error::ConnectionFailed) do
      client.get(@ssl_fake_url + 'hello')
    end
  end

  def test_108_basic_auth
    @client.basic_auth('admin', 'admin')
    assert_equal('basic_auth OK', @client.get(@url + 'basic_auth').body)
  end

  def test_109_digest_auth
    flunk('digest auth is not supported')
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
    flunk 'custom method not supported'
  end

  def test_206_response_header
    assert_match(/WEBrick/, @client.get(@url + 'hello').headers[:server])
  end

  def test_207_cookies
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

  def test_208_redirect
    assert_equal('hello', @client.get(@url + 'redirect3').body)
  end

  def test_209_redirect_loop_detection
    assert_raise(RuntimeError) do
      @client.get(@url + 'redirect_self')
    end
  end

  def test_2091_urlencoded
    assert_equal('1=2&3=4', @client.post(@url + 'servlet', {'1' => '2', '3' => '4'}).headers[:x_query])
  end

  def test_210_post_multipart
    url = URI.parse(@url)
    @client = Faraday.new(:url => (url + "/").to_s) { |builder|
      builder.request :multipart
      builder.adapter :net_http
    }
    res = @client.post(@url + 'servlet', :upload => Faraday::UploadIO.new(__FILE__, 'text/plain'))
    assert_match(/FIND_TAG_IN_THIS_FILE/, res.body)
    #
    @client = Faraday.new(:url => (url + "/").to_s) { |builder|
      builder.request :multipart
    }
    res = @client.post(@url + 'servlet', :upload => Faraday::UploadIO.new(__FILE__, 'text/plain'))
    assert_match(/FIND_TAG_IN_THIS_FILE/, res.body.read)
  end

  def test_211_streaming_upload
    file = Tempfile.new(__FILE__)
    file << "*" * 4096 * 100
    file.close
    file.open
    res = @client.put(@url + 'chunked', file)
    assert(res.header['x-count'][0].to_i >= 100)
    if filename = res.header['x-tmpfilename'][0]
      File.unlink(filename)
    end
  end

  def test_212_streaming_download
    flunk('streaming download not supported')
  end

  def test_213_gzip_get
    assert_equal('hello', @client.get(@url + 'compressed?enc=gzip').body)
    assert_equal('hello', @client.get(@url + 'compressed?enc=deflate').body)
  end

  def test_214_gzip_post
    assert_equal('hello', @client.post(@url + 'compressed', 'enc=gzip').body)
    assert_equal('hello', @client.post(@url + 'compressed', 'enc=deflate').body)
  end

  def test_215_charset
    body = @client.get(@url + 'charset').body
    assert_equal(Encoding::EUC_JP, body.encoding)
    assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
  end
end
