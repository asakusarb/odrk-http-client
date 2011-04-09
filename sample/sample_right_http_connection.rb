require 'uri'
# right_http_connection silently depends on active_support/core/ext (Object#blank?)
require 'active_support/core_ext/object/blank'
require 'right_http_connection'

require File.expand_path('sample_setting', File.dirname(__FILE__))
url = URI.parse(@url)

# prepare utility methods
def get(url, path, opt = {})
  request = Net::HTTP::Get.new(path)
  req(request, url, opt)
end

def post(url, path, form, opt = {})
  request = Net::HTTP::Post.new(path)
  request.set_form_data(form)
  req(request, url, opt)
end

def req(request, url, opt = {})
  opt.merge(
    :request => request,
    :server => url.host,
    :port => url.port,
    :protocol => url.scheme
  )
end

# simple GET
conn = Rightscale::HttpConnection.new
p conn.request(get(url, '/')).body.size

# get response header
p conn.request(get(url, '/')).header

# post form
p conn.request(post(url, '/', :query => 'ruby')).body.size

# get response header
# post form

# proxy
proxy = URI.parse(@proxy) if @proxy

if proxy
  opt = {
    :proxy_host => proxy.host,
    :proxy_port => proxy.port,
    :proxy_username => proxy.user,
    :proxy_password => proxy.password
  }
else
  opt = {}
end

conn = Rightscale::HttpConnection.new(opt)
req = {
  :request => Net::HTTP::Get.new(url.path),
  :server => url.host,
  :port => url.port,
  :protocol => url.scheme
}

body = conn.request(req).body
conn.finish

p body.size
