require 'uri'
require 'net/http'

require File.expand_path('sample_setting', File.dirname(__FILE__))
url = URI.parse(@url)
proxy = URI.parse(@proxy) if @proxy

if proxy
  c = Net::HTTP::Proxy(proxy.host, proxy.port, proxy.user, proxy.password).new(url.host, url.port)
else
  c = Net::HTTP.new(url.host, url.port)
end

c.start
begin
  body = c.get(url.path).read_body
ensure
  c.finish
end
p body.size
