require 'simplehttp'

url = ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html'
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']

http = SimpleHttp.new(url)
http.set_proxy(proxy) if proxy
body = http.get
p body.size
