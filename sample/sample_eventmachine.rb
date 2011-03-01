require 'uri'
require 'eventmachine'

url = URI.parse(ARGV.shift || 'http://www.google.co.jp/')
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
proxy = URI.parse(proxy) if proxy

body = nil
EM.run do
  done = false
  if proxy
    host, port = proxy.host, proxy.port
  else
    host, port = url.host, url.port
  end
  path = proxy ? url.to_s : url.path
  requests = 0
  client = EM::Protocols::HttpClient2.connect(host, port)
  req = client.get(proxy ? url.to_s : url.path)
  req.callback {
    body = req.content
    EM.stop if done
  }
  done = true
end

p body.size
