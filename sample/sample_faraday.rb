require 'uri'
require 'faraday'

require File.expand_path('sample_setting', File.dirname(__FILE__))
url = URI.parse(@url)

conn = Faraday.new(:url => (url + "/").to_s) { |builder|
#  builder.adapter :typhoeus
  builder.adapter :net_http # for proxy
}
if @proxy
  conn.proxy(:uri => @proxy, :user => @proxy_user, :password => @proxy_pass)
end

body = conn.get(url.path).body
p body.size
