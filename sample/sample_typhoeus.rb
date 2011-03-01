require 'typhoeus'

url = ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html'
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']

# Easier API:
# body = Typhoeus::Request.get(url, :proxy => proxy).body

request = Typhoeus::Request.new(url, :proxy => proxy)

hydra = Typhoeus::Hydra.new
hydra.queue(request)
hydra.run

body = request.response.body
p body.size
