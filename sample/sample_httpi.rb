require 'httpi'

require File.expand_path('sample_setting', File.dirname(__FILE__))

HTTPI.adapter = :curb
p HTTPI.get(HTTPI::Request.new(@url)).body.size
HTTPI.adapter = :httpclient
p HTTPI.get(HTTPI::Request.new(@url)).body.size
HTTPI.adapter = :net_http
p HTTPI.get(HTTPI::Request.new(@url)).body.size
