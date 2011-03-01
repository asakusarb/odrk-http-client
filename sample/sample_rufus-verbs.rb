require 'uri'
require 'rufus-verbs'

url = URI.parse(ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html')
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
proxy = URI.parse(proxy) if proxy


class RufusVerbsClient
  include Rufus::Verbs

  def run(params)
    get(params)
  end
end

req = {:uri => url.to_s, :proxy => proxy ? proxy.to_s : nil}
body = RufusVerbsClient.new.run(req).body
p body.size
