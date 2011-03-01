require 'uri'
require 'httpclient'

url = ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html'
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']

c = HTTPClient.new(proxy)
body = c.get(url).content
p body.size
