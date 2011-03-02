require 'uri'
# right_http_connection silently depends on active_support/core/ext (Object#blank?)
require 'active_support/core_ext/object/blank'
require 'right_http_connection'

require File.expand_path('sample_setting', File.dirname(__FILE__))
url = URI.parse(@url)
proxy = URI.parse(@proxy) if @proxy

if proxy
  opt = {
    :proxy_host => proxy.host,
    :proxy_port => proxy.port,
    :proxy_username => proxy.user,
    :proxy_password => proxy.password
  }
else
  opt = {}
end

conn = Rightscale::HttpConnection.new(opt)
req = {
  :request => Net::HTTP::Get.new(url.path),
  :server => url.host,
  :port => url.port,
  :protocol => url.scheme
}

body = conn.request(req).read_body
conn.finish

p body.size
