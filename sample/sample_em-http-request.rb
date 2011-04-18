require 'em-http' # requires '1.0.0.beta.3' gem which can be obtained with --pre

require File.expand_path('sample_setting', File.dirname(__FILE__))

body = nil
EM.run do
  if @proxy
    proxy = URI.parse(@proxy)
    opt = {:proxy => {:host => proxy.host, :port => proxy.port, :authorization => [@proxy_user, @proxy_pass]}}
  else
    opt = {}
  end 
  req = EventMachine::HttpRequest.new(@url, opt).get
  req.callback {
    body = req.response
    EM.stop
  }
end

p body.size
