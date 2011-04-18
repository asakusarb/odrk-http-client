require 'uri'

@url = ARGV.shift || 'http://www.ruby-lang.org/ja/'
@proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
if @proxy
  proxy_uri = URI.parse(@proxy)
  @proxy_user = proxy_uri.user
  @proxy_pass = proxy_uri.password
end
