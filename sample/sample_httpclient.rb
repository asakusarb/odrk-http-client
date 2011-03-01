requrie 'uri'
require 'httpclient'

url = URI.parse(ARGV.shift || 'http://www.google.co.jp/')
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
proxy = URI.parse(proxy) if proxy

c = HTTPClient.new(proxy)
body = c.get(url).content
p body.size
