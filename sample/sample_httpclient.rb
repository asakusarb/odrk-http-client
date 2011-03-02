require 'httpclient'

require File.expand_path('sample_setting', File.dirname(__FILE__))

client = HTTPClient.new(@proxy)
body = client.get(@url).content
p body.size
