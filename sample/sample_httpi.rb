require 'httpi'

require File.expand_path('sample_setting', File.dirname(__FILE__))

p HTTPI.get(@url, :curb).body.size
p HTTPI.get(@url, :httpclient).body.size
p HTTPI.get(@url, :net_http).body.size
