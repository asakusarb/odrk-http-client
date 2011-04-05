# -*- encoding: utf-8 -*-
require 'eventmachine'
require File.expand_path('./test_setting', File.dirname(__FILE__))


class TestEventMachine < OdrkHTTPClientTestCase
  def request(method, url)
    content = nil
    url = URI.parse(url)
    EM.run do
      client = EM::Protocols::HttpClient2.connect(:host => url.host, :port => url.port, :ssl => url.scheme == 'https')
      req = client.send(method, url.path)
      req.callback {
        content = req.content
        EM.stop
      }
    end
    content
  end

  def test_gzip_get
    assert_equal('hello', request(:get, @url + 'compressed?enc=gzip'))
    assert_equal('hello', request(:get, @url + 'compressed?enc=deflate'))
  end

  def test_gzip_post
    raise "XXX there's no way to supply a POST body.."
  end

  def test_put
    raise 'PUT/DELETE is not supported'
  end

  def test_cookies
    raise 'Cookie is not supported'
  end

  def test_post_multipart
    raise 'POST is not supported'
  end
end
