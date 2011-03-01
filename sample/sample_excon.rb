require 'excon'

url = ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html'
# proxy is not supported.
# proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
# proxy = URI.parse(proxy) if proxy

body = Excon.get(url).body

p body.size
