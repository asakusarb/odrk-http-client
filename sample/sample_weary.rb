require 'weary'

require File.expand_path('sample_setting', File.dirname(__FILE__))

$url = @url

class WearyClient < Weary::Client
  domain 'http://dev.ctor.org/'

  get :fetch, ""
end

p future = WearyClient.new.fetch.perform

p future.body.size
