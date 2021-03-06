require 'uri'
require 'eventmachine'

require File.expand_path('sample_setting', File.dirname(__FILE__))
# No proxy support.
url = URI.parse(@url)

body = nil
EM.run do
  client = EM::Protocols::HttpClient2.connect(:host => url.host, :port => url.port, :ssl => url.scheme == 'https')
  req = client.get(url.path)
  req.callback {
    body = req.content
    EM.stop
  }
end

p body.size
