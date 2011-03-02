require 'uri'
require 'patron'

require File.expand_path('sample_setting', File.dirname(__FILE__))
url = URI.parse(@url)
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']

sess = Patron::Session.new
sess.base_url = (url + "/").to_s
sess.proxy = @proxy
body = sess.get(url.path).body
p body.size
