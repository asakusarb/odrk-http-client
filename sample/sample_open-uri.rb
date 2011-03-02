require 'open-uri'

require File.expand_path('sample_setting', File.dirname(__FILE__))

if @proxy_user
  opt = {:proxy_http_basic_authentication => [@proxy, @proxy_user, @proxy_pass]}
elsif @proxy
  opt = {:proxy => @proxy}
else
  opt = {}
end
body = open(@url, opt) { |f| f.read }
p body.size
