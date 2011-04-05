# -*- encoding: utf-8 -*-
require 'typhoeus'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestTyphoeus < OdrkHTTPClientTestCase
  def setup
    super
    @client = Typhoeus::Request
  end

  def test_ssl
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    assert_equal("Peer certificate cannot be authenticated with known CA certificates", @client.get(ssl_url + 'hello').curl_error_message)
  end

  def test_ssl_ca
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    assert_equal('hello ssl', @client.get(ssl_url + 'hello', :ssl_cacert => ca_file).body)
  end

  def test_ssl_hostname
    setup_sslserver
    ssl_url = "https://127.0.0.1:#{$ssl_port}/"
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    assert_equal("SSL peer certificate or SSH remote key was not OK", @client.get(ssl_url + 'hello', :ssl_cacert => ca_file).curl_error_message)
  end

  def test_gzip_get
    assert_equal('hello', @client.get(@url + 'compressed?enc=gzip').body)
    assert_equal('hello', @client.get(@url + 'compressed?enc=deflate').body)
  end

  def test_gzip_post
    assert_equal('hello', @client.post(@url + 'compressed', :params => {:enc => 'gzip'}).body)
    assert_equal('hello', @client.post(@url + 'compressed', :params => {:enc => 'deflate'}).body)
  end

  def test_post
    res = @client.post(@url + 'servlet', :params => {1=>2, 3=>4})
    res = @client.post(@url + 'servlet', :params => {1=>2, 3=>4})
  end

  def test_put
    assert_equal("put", @client.put(@url + 'servlet').body)
    res = @client.put(@url + 'servlet', :body => '1=2&3=4')
    # !! res.headers is a String.
    assert_match(/X-Query: 1=2&3=4/, res.headers)
    # bytesize
    res = @client.put(@url + 'servlet', :body => 'txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A')
    assert_match(/X-Query: txt=%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A/, res.headers)
    assert_match(/X-Size: 15/, res.headers)
  end

  def test_delete
    assert_equal("delete", @client.delete(@url + 'servlet').body)
  end

  def test_cookies
    res = @client.get(@url + 'cookies', :headers => {'Cookie' => 'foo=0; bar=1'})
    # !! It returns 'Set-Cookie'. 2 or more response headers causes strange behavior?
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

  def test_post_multipart
    File.open(__FILE__) do |file|
      res = Typhoeus::Request.post(@url + 'servlet', :params => {:upload => file})
      assert_match(/FIND_TAG_IN_THIS_FILE/, res.body)
    end
  end

  def test_basic_auth
    assert_equal('basic_auth OK', Typhoeus::Request.get(@url + 'basic_auth', :username => 'admin', :password => 'admin', :auth_method => :basic).body)
  end

  def test_digest_auth
    assert_equal('digest_auth OK', Typhoeus::Request.get(@url + 'digest_auth', :username => 'admin', :password => 'admin', :auth_method => :digest).body)
    # digest_sess
    assert_equal('digest_sess_auth OK', Typhoeus::Request.get(@url + 'digest_sess_auth', :username => 'admin', :password => 'admin', :auth_method => :digest).body)
  end

  def test_redirect
    res = Typhoeus::Request.get(@url + 'redirect3', :follow_location => true)
    assert_equal('hello', res.body)
  end

  def test_redirect_loop_detection
    res = Typhoeus::Request.get(@url + 'redirect_self', :follow_location => true, :max_redirects => 10)
    assert_equal("Number of redirects hit maximum amount", res.curl_error_message)
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
end
