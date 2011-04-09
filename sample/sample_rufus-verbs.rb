require 'rufus-verbs'

require File.expand_path('sample_setting', File.dirname(__FILE__))

# 1 Object per client.
# include Rufus::Verbs and call get, post, etc. (private methods) 
class RufusVerbsClient
  include Rufus::Verbs
end

$url = @url

# simple GET
RufusVerbsClient.new.instance_eval {
  p get($url).body.size
}

# get response header
RufusVerbsClient.new.instance_eval {
  p get($url).header["content-type"]
}

# post form
RufusVerbsClient.new.instance_eval {
  p post($url, :query => 'ruby')
}

# proxy
$proxy = @proxy
body = RufusVerbsClient.new.instance_eval {
  get(:uri => $url, :proxy => $proxy).body
}
p body.size
