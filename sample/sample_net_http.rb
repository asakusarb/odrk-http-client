require 'uri'
require 'net/http'

require File.expand_path('sample_setting', File.dirname(__FILE__))
url = URI.parse(@url)

# simple GET
p Net::HTTP.get(url).size

# get response header
p Net::HTTP.get_response(url).header

# post form
p Net::HTTP.new(url.host, url.port).post(url.path, 'query=ruby').size

# proxy
proxy = URI.parse(@proxy) if @proxy
if proxy
  c = Net::HTTP::Proxy(proxy.host, proxy.port, proxy.user, proxy.password).new(url.host, url.port)
else
  c = Net::HTTP.new(url.host, url.port)
end
body = c.get(url.path).body
p body.size
