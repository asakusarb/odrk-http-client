require 'uri'
require 'rfuzz/session'

url = ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html'
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
proxy = URI.parse(proxy) if proxy

if proxy
  host, port = proxy.host, proxy.port
  path = url.to_s
else
  host, port = url.host, url.port
  path = url.path
end

body = RFuzz::HttpClient.new(host, port).get(path).http_body
p body.size
