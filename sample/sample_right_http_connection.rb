require 'active_support/all'
require 'right_http_connection'

url = URI.parse(ARGV.shift || 'http://www.google.com/')
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
proxy = URI.parse(proxy) if proxy

conn = Rightscale::HttpConnection.new
req = {
  :request => Net::HTTP::Get.new(url.path),
  :server => url.host,
  :port => url.port,
  :protocol => 'http'
}
if proxy
  req.merge(
    :proxy_host => proxy.host,
    :proxy_port => proxy.port
  )
end
body = conn.request(req).read_body
conn.finish

p body.size
