require 'uri'
require 'test/unit'
require File.expand_path('./httpserver', File.dirname(__FILE__))
require File.expand_path('./sslserver', File.dirname(__FILE__))

$host = 'localhost'
$port = 17171
$ssl_port = 17172

$url = "http://#{$host}:#{$port}/"

class OdrkHTTPClientTestCase < Test::Unit::TestCase
  def setup
    @server = HTTPServer.new($host, $port)
    @url = $url
  end

  def teardown
    @server.shutdown
    @ssl_server.shutdown if @ssl_server
  end

  def setup_sslserver
    @ssl_server = SSLServer.new('localhost', $ssl_port)
  end
end

