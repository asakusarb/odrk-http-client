require 'restclient'

require File.expand_path('sample_setting', File.dirname(__FILE__))

RestClient.proxy = @proxy if @proxy
body = RestClient.get(@url)
p body.size
