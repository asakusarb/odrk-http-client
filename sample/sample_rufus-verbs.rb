require 'rufus-verbs'

require File.expand_path('sample_setting', File.dirname(__FILE__))

class RufusVerbsClient
  include Rufus::Verbs

  def run(params)
    get(params)
  end
end

body = RufusVerbsClient.new.run(:uri => @url, :proxy => @proxy).body
p body.size
