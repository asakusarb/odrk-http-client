require 'uri'
require 'simplehttp'

require File.expand_path('sample_setting', File.dirname(__FILE__))
proxy = URI.parse(@proxy) if @proxy

http = SimpleHttp.new(@url)
http.set_proxy(proxy.hostname, proxy.port, proxy.user, proxy.password) if proxy
body = http.get
p body.size
