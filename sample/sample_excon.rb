require 'excon'

require File.expand_path('sample_setting', File.dirname(__FILE__))
# proxy is not supported.

body = Excon.get(@url).body

p body.size
