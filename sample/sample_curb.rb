require 'curb'

url = ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html'
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']

# body = Curl::Easy.http_get(url).body_str

curl = Curl::Easy.new(url)
curl.proxy_url = proxy
curl.http_get
body = curl.body_str
p body.size
