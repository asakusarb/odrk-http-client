require 'wrest'

require File.expand_path('sample_setting', File.dirname(__FILE__))
# proxy is not supported.
# proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']

Wrest.use_curl! # use Patron.
Wrest.logger.level = Logger::FATAL

body = @url.to_uri.get.body
p body.size
