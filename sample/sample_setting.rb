require 'uri'

@url = ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html'
@proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
if @proxy
  proxy_uri = URI.parse(@proxy)
  @proxy_user = proxy_uri.user
  @proxy_pass = proxy_uri.password
end
