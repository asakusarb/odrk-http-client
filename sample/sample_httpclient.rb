require 'uri'
require 'httpclient'

url = URI.parse(ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html')
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
proxy = URI.parse(proxy) if proxy

c = HTTPClient.new(proxy)
body = c.get(url).content
p body.size
