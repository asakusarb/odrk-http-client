require 'restclient'

require File.expand_path('sample_setting', File.dirname(__FILE__))

# simple GET
p RestClient.get(@url).size

# get response header
p RestClient.get(@url).headers[:content_type]

# post form
p RestClient.post(@url, :query => 'ruby').size 

# proxy
RestClient.proxy = @proxy if @proxy
body = RestClient.get(@url)
p body.size
