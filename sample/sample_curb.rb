require 'curb'

require File.expand_path('sample_setting', File.dirname(__FILE__))
# body = Curl::Easy.http_get(url).body_str

curl = Curl::Easy.new(@url)
curl.proxy_url = @proxy
curl.http_get
body = curl.body_str
p body.size
