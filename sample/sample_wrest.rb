require 'wrest'

url = ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html'
# proxy is not supported.
# proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']

Wrest.use_curl! # use Patron.

body = url.to_uri.get.body
p body.size
