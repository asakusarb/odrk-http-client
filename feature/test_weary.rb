# -*- encoding: utf-8 -*-
require 'weary'
require File.expand_path('./test_setting', File.dirname(__FILE__))

class TestWeary < OdrkHTTPClientTestCase
  def client(url)
    c = Class.new(Weary::Client)
    c.domain(url)
    c.get :get, '/{path}'
    c.post :post, '/{path}'
    c.put :put, '/{path}' do |resource|
      resource.optional '1', '3'
    end
    c.get :basic_auth, '/{path}' do |resource|
      resource.basic_auth! 'admin', 'admin'
    end
    c.new
  end

  def test_101_proxy
    flunk 'not supported'
  end

  def test_102_proxy_auth
    flunk 'not supported'
  end

  def test_103_keepalive
    flunk 'not supported'
  end

  def test_104_pipelining
    flunk 'not supported'
  end

  def test_105_ssl
    setup_sslserver
    assert_raise(OpenSSL::SSL::SSLError) do
      client(@ssl_url).post(:path => 'hello').perform.body
    end
  end

  def test_106_ssl_ca
    flunk 'not supported'
  end

  def test_107_ssl_hostname
    flunk 'not supported'
  end

  def test_108_basic_auth
    assert_equal('basic_auth OK', client(@url).basic_auth(:path => 'basic_auth').perform.body)
  end

  def test_109_digest_auth
    flunk 'not supported'
  end

  def test_201_get
    assert_equal('hello', client(@url).get(:path => 'hello').perform.body)
  end

  def test_202_post
    assert_equal('hello', client(@url).post(:path => 'hello', :dummy => 'body').perform.body)
  end

  def test_203_put
    assert_equal("put", client(@url).put(:path => 'servlet').perform.body)
    res = client(@url).put(:path => 'servlet', :body => {:'1' => '2', :'3' => '4'})
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
end
