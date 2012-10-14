# -*- encoding: utf-8 -*-
# right_http_connection silently depends on active_support/core/ext (Object#blank?)
require 'active_support/core_ext/object/blank'
require 'right_http_connection'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestRightHttpConnection < OdrkHTTPClientTestCase
  def setup
    super
    @client = Rightscale::HttpConnection.new
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

  def test_101_proxy
    setup_proxyserver
    url = URI.parse(@url)
    proxy = URI.parse(@proxy_url)
    client = Rightscale::HttpConnection.new(:proxy_host => proxy.host, :proxy_port => proxy.port)
    assert_equal('hello', client.request(get(url, url.path + 'hello')).body)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_102_proxy_auth
    setup_proxyserver(true)
    url = URI.parse(@url)
    proxy = URI.parse(@proxy_url)
    client = Rightscale::HttpConnection.new(:proxy_host => proxy.host, :proxy_port => proxy.port, :proxy_username => 'admin', :proxy_password => 'admin')
    assert_equal('hello', client.request(get(url, url.path + 'hello')).body)
    assert_match(/accept/, @proxy_server.log, 'not via proxy')
  end

  def test_103_keepalive
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

  def test_104_pipelining
    flunk 'not supported'
  end

  def test_105_ssl
    setup_sslserver
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.request(get(URI.parse(@ssl_url), '/hello'))
    end
  end

  def test_106_ssl_ca
    setup_sslserver
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    assert_equal('hello ssl', @client.request(get(URI.parse(@ssl_url), '/hello', :ca_file => ca_file, :fail_if_ca_mismatch => true)).body)
  end

  def test_107_ssl_hostname
    setup_sslserver
    ca_file = File.expand_path('./fixture/ca_all.pem', File.dirname(__FILE__))
    assert_raise(OpenSSL::SSL::SSLError) do
      @client.request(get(URI.parse(@ssl_fake_url), '/hello', :ca_file => ca_file, :fail_if_ca_mismatch => true))
    end
  end

  def test_108_basic_auth
    url = URI.parse(@url)
    method = Net::HTTP::Get.new('/basic_auth')
    method.basic_auth('admin', 'admin')
    assert_equal('basic_auth OK', @client.request(req(method, url)).body)
  end

  def test_109_digest_auth
    flunk 'digest auth not supported'
    flunk 'digest-sess auth not supported'
  end

  def test_201_get
    assert_equal('hello', @client.request(get(@url, 'hello')).body)
  end

  def test_202_post
    assert_equal('hello', @client.request(post(@url, 'hello', 'body')).body)
  end

  def test_203_put
    flunk 'no direct support for put'
  end

  def test_delete
    flunk 'no direct support for delete'
  end

  def test_custom_method
    flunk 'custom method not directly supported'
  end

  def test_cookies
    flunk 'not supported'
  end

  def test_post_multipart
    url = URI.parse(@url)
    File.open(__FILE__) do |file|
      method = Net::HTTP::Post.new('/servlet')
      method.set_form({'upload' => file}, 'multipart/form-data')
      res = @client.request(req(method, url))
      content = res.body
      assert_match(/FIND_TAG_IN_THIS_FILE/, content)
    end
  end

  def test_redirect
    url = URI.parse(@url)
    assert_equal('hello', @client.request(get(url, '/redirect3')))
  end

  def test_streaming_upload
    file = Tempfile.new(__FILE__)
    file << "*" * 4096 * 100
    file.close
    file.open
    url = URI.parse(@url)
    res = @client.request(post(url, '/chunked', file))
    assert(res.header['x-count'].to_i >= 7)
    if filename = res.header['x-tmpfilename']
      File.unlink(filename)
    end
  end

  def test_streaming_download
    url = URI.parse(@url)
    c = 0
    @client.request(get(url, '/largebody')) do |res|
      res.read_body do |str|
        c += 1
      end
    end
    assert(c > 600)
  end

  def test_gzip_get
    url = URI.parse(@url)
    assert_equal('hello', @client.request(get(url, '/compressed?enc=gzip')).body)
    assert_equal('hello', @client.request(get(url, '/compressed?enc=deflate')).body)
  end

  def test_gzip_post
    url = URI.parse(@url)
    assert_equal('hello', @client.request(post(url, '/compressed', :enc => 'gzip')).body)
    assert_equal('hello', @client.request(post(url, '/compressed', :enc => 'deflate')).body)
  end

  def test_charset
    url = URI.parse(@url)
    body = @client.request(get(url, '/charset')).body
    assert_equal(Encoding::EUC_JP, body.encoding)
    assert_equal('あいうえお'.encode(Encoding::EUC_JP), body)
  end
end

