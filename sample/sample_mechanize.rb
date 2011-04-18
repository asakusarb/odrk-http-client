require 'mechanize'

require File.expand_path('sample_setting', File.dirname(__FILE__))

client = Mechanize.new
if @proxy
  proxy = URI.parse(@proxy)
  client.set_proxy(proxy.host, proxy.port, proxy.user, proxy.password)
end

body = client.get(@url).content
p body.size
