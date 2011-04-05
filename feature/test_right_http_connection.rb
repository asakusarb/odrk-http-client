# -*- encoding: utf-8 -*-
# right_http_connection silently depends on active_support/core/ext (Object#blank?)
require 'active_support/core_ext/object/blank'
require 'right_http_connection'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestRightHttpConnection < OdrkHTTPClientTestCase
  def setup
    super
    @client = Rightscale::HttpConnection.new
    @url = URI.parse($url)
  end

  def get(url, path, opt = {})
    request = Net::HTTP::Get.new(path)
    req(request, url, opt)
  end

  def post(url, path, form, opt = {})
    request = Net::HTTP::Post.new(path)
    request.set_form_data(form)
    req(request, url, opt)
  end

  def req(request, url, opt = {})
    opt.merge(
      :request => request,
      :server => url.host,
      :port => url.port,
      :protocol => url.scheme
    )
  end

  def test_ssl
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.request(get(URI.parse(ssl_url), '/hello'))
    end
  end

  def test_ssl_ca
    setup_sslserver
    ssl_url = "https://localhost:#{$ssl_port}/"
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    assert_equal('hello ssl', @client.request(get(URI.parse(ssl_url), '/hello', :ca_file => ca_file, :fail_if_ca_mismatch => true)).body)
  end

  def test_ssl_hostname
    setup_sslserver
    ssl_url = "https://127.0.0.1:#{$ssl_port}/"
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.request(get(URI.parse(ssl_url), '/hello', :ca_file => ca_file, :fail_if_ca_mismatch => true))
    end
  end

  def test_gzip_get
    assert_equal('hello', @client.request(get(@url, '/compressed?enc=gzip')).body)
    assert_equal('hello', @client.request(get(@url, '/compressed?enc=deflate')).body)
  end

  def test_gzip_post
    assert_equal('hello', @client.request(post(@url, '/compressed', :enc => 'gzip')).body)
    assert_equal('hello', @client.request(post(@url, '/compressed', :enc => 'deflate')).body)
  end

  def test_put
    flunk 'no direct support for put'
  end

  def test_delete
    flunk 'no direct support for delete'
  end

  def test_cookies
    flunk 'not supported'
  end

  def test_post_multipart
    File.open(__FILE__) do |file|
      method = Net::HTTP::Post.new('/servlet')
      method.set_form({'upload' => file}, 'multipart/form-data')
      res = @client.request(req(method, @url))
      content = res.body
      assert_match(/FIND_TAG_IN_THIS_FILE/, content)
    end
  end

  def test_basic_auth
    method = Net::HTTP::Get.new('/basic_auth')
    method.basic_auth('admin', 'admin')
    assert_equal('basic_auth OK', @client.request(req(method, @url)).body)
  end

  def test_digest_auth
    flunk 'digest auth not supported'
    flunk 'digest-sess auth not supported'
  end

  def test_redirect
    assert_equal('hello', @client.request(get(@url, '/redirect3')))
  end

  def test_keepalive
    server = HTTPServer::KeepAliveServer.new($host)
    begin
      5.times do
        assert_equal('12345', @client.request(get(URI.parse(server.url), '/')).body)
      end
    ensure
      server.close
    end
    # chunked
    server = HTTPServer::KeepAliveServer.new($host)
    begin
      5.times do
        assert_equal('abcdefghijklmnopqrstuvwxyz1234567890abcdef', @client.request(get(URI.parse(server.url), '/chunked')).body)
      end
    ensure
      server.close
    end
  end
end

