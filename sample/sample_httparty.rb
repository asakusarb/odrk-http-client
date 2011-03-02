require 'uri'
require 'httparty'

require File.expand_path('sample_setting', File.dirname(__FILE__))
proxy = URI.parse(@proxy) if @proxy

class HTTPartyClient
  include HTTParty
end

HTTPartyClient.http_proxy(proxy.host, proxy.port) if proxy
body = HTTPartyClient.get(@url)

p body.size
