require 'uri'
require 'test/unit'
require 'tempfile'
require File.expand_path('./httpserver', File.dirname(__FILE__))
require File.expand_path('./sslserver', File.dirname(__FILE__))
require File.expand_path('./proxyserver', File.dirname(__FILE__))

$host = 'localhost'
$port = 17171
$ssl_port = 17172
$proxy_port = 17173

class OdrkHTTPClientTestCase < Test::Unit::TestCase
  def setup
    @server = HTTPServer.new($host, $port)
    @ssl_server = nil
    @proxy_server = nil
    @url = "http://#{$host}:#{$port}/"
    @proxy_url = "http://#{$host}:#{$proxy_port}/"
  end

  def teardown
    @server.shutdown
    @ssl_server.shutdown if @ssl_server
    @proxy_server.shutdown if @proxy_server
  end

  def setup_sslserver
    @ssl_server = SSLServer.new('localhost', $ssl_port)
  end

  def setup_proxyserver(auth = false)
    @proxy_server = ProxyServer.new('localhost', $proxy_port, auth)
  end
end

