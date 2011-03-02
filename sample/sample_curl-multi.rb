# CAUTION: It only runs on CRuby 1.8
# curl-multi depends on RubyInline and inlined C code is not compatible with 1.9.

require 'curl-multi'

require File.expand_path('sample_setting', File.dirname(__FILE__))

curl = Curl::Multi.new
body = nil
on_success = lambda { |res|
  body = res
}
curl.get(@url, on_success)
curl.select([], []) while curl.size > 0

p body.size
