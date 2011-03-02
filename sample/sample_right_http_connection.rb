require 'uri'
require 'active_support/all' # right_http_connection depends on active_support/core/ext (Object#blank?)
require 'right_http_connection'

url = URI.parse(ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html')
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
proxy = URI.parse(proxy) if proxy

if proxy
  conn = Rightscale::HttpConnection.new(:proxy_host => proxy.host, :proxy_port => proxy.port)
else
  conn = Rightscale::HttpConnection.new
end
req = {
  :request => Net::HTTP::Get.new(url.path),
  :server => url.host,
  :port => url.port,
  :protocol => 'http'
}

body = conn.request(req).read_body
conn.finish

p body.size
