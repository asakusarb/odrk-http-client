require 'open-uri'

url = ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html'
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']

body = open(url, :proxy => proxy) { |f| f.read }
p body.size
