require 'uri'
require 'httparty'

require File.expand_path('sample_setting', File.dirname(__FILE__))
proxy = URI.parse(@proxy) if @proxy

# 1 Class for client.
# For concurrency, you need to create anonymous Class like;
# client = Class.new; client.instance_eval { include HTTParty }
class HTTPartyClient
  include HTTParty
end

# simple GET
p HTTPartyClient.get(@url).size

# get response header
p HTTPartyClient.get(@url).header["content-type"]

# post form
p HTTPartyClient.post(@url, :body => 'query=ruby').size

# proxy
HTTPartyClient.http_proxy(proxy.host, proxy.port) if proxy
body = HTTPartyClient.get(@url)

p body.size
