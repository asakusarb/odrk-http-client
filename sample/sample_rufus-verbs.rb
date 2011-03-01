require 'rufus-verbs'

url = ARGV.shift || 'http://www.ci.i.u-tokyo.ac.jp/~sasada/joke-intro.html'
proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']

class RufusVerbsClient
  include Rufus::Verbs

  def run(params)
    get(params)
  end
end

body = RufusVerbsClient.new.run(:uri => url, :proxy => proxy).body
p body.size
