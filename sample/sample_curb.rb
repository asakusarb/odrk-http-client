require 'curb'

require File.expand_path('sample_setting', File.dirname(__FILE__))
# body = Curl::Easy.http_get(url).body_str

curl = Curl::Easy.new(@url)
curl.ssl_verify_peer = true
if $DEBUG
  curl.on_debug { |*arg|
    p arg
  }
end

curl.proxy_url = @proxy
curl.http_get
body = curl.body_str
p body.size

=begin
multi = Curl::Multi.new
multi.add(Curl::Easy.new(@url))
multi.add(Curl::Easy.new(@url))
multi.add(Curl::Easy.new(@url))

multi.perform do
  puts "hello"
end
=end
