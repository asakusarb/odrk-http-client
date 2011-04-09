require 'uri'
require 'simplehttp'

require File.expand_path('sample_setting', File.dirname(__FILE__))

# simple GET
p SimpleHttp.new(@url).get.size

# get response header
conn = SimpleHttp.new(@url)
conn.get
p conn.response_headers["content-type"]

# post form
p SimpleHttp.new(@url).post('query' => 'ruby').size

# proxy
proxy = URI.parse(@proxy) if @proxy
http = SimpleHttp.new(@url)
http.set_proxy(proxy.hostname, proxy.port, proxy.user, proxy.password) if proxy
body = http.get
p body.size
