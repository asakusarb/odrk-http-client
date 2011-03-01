require 'uri'
require 'httparty'

url = URI.parse(ARGV.shift || 'http://www.google.co.jp/')
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
proxy = URI.parse(proxy) if proxy

class HTTPartyClient
  include HTTParty
end

HTTPartyClient.http_proxy(proxy.host, proxy.port) if proxy
body = HTTPartyClient.get(url.to_s)

p body.size
