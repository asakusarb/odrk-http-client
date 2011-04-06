require 'excon'

require File.expand_path('sample_setting', File.dirname(__FILE__))

if @proxy
  body = Excon.new(@url, :proxy => @proxy).request(:method => :get).body
else
  body = Excon.get(@url).body
end

p body.size
