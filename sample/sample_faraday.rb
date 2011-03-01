require 'uri'
require 'faraday'

url = URI.parse(ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html')
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']

conn = Faraday.new(:url => (url + "/").to_s, :proxy => proxy) { |builder|
  builder.adapter :typhoeus
}

body = conn.get(url.path).body
p body.size
