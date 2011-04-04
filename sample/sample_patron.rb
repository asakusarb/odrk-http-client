require 'uri'
require 'patron'

require File.expand_path('sample_setting', File.dirname(__FILE__))
url = URI.parse(@url)

sess = Patron::Session.new
sess.connect_timeout = sess.timeout = 30 # 5 [sec] by default.
sess.base_url = (url + "/").to_s
sess.proxy = @proxy
path = url.path.sub(/^\//, '')
body = sess.get(path).body
p body.size
