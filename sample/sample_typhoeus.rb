require 'typhoeus'

require File.expand_path('sample_setting', File.dirname(__FILE__))

# Easier API:
# body = Typhoeus::Request.get(@url, :proxy => @proxy).body

request = Typhoeus::Request.new(@url, :proxy => @proxy)

hydra = Typhoeus::Hydra.new
hydra.queue(request)
hydra.run

body = request.response.body
p body.size
