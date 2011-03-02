require 'rfuzz/session'

require File.expand_path('sample_setting', File.dirname(__FILE__))
url = URI.parse(@url)
# proxy is not supported.

body = RFuzz::HttpClient.new(url.host, url.port).get(url.path).http_body
p body.size
