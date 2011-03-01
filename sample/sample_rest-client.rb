require 'rest_client'

url = ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html'
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']

RestClient.proxy = proxy if proxy
body = RestClient.get(url)
p body.size
