# CAUTION: It only runs on CRuby 1.8
# curl-multi depends on RubyInline and inlined C code is not compatible with 1.9.

require 'curl-multi'

url = ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html'
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']

curl = Curl::Multi.new
body = nil
on_success = lambda { |res|
  body = res
}
curl.get(url, on_success)
curl.select([], []) while curl.size > 0

p body.size
