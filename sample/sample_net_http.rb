require 'uri'
require 'net/http'

url = URI.parse(ARGV.shift || 'http://www.google.co.jp/')
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
proxy = URI.parse(proxy) if proxy

if proxy
  c = Net::HTTP::Proxy(proxy.host, proxy.port).new(url.host, url.port)
else
  c = Net::HTTP.new(url.host, url.port)
end

c.start
begin
  body = c.get(url.path).read_body
ensure
  c.finish
end
