require 'restfulie'

require File.expand_path('sample_setting', File.dirname(__FILE__))

obj = Restfulie.at(@url)
p obj.get.body.size
