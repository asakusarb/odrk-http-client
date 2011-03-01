require 'uri'
require 'patron'

url = URI.parse(ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html')
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']

sess = Patron::Session.new
sess.base_url = (url + "/").to_s
sess.proxy = proxy
body = sess.get(url.path).body
p body.size
