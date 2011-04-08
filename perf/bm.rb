require 'net/http'
require 'open-uri'
require 'httparty'
require 'rest-client'
require 'right_http_connection'
require 'rufus-verbs'
require 'simplehttp'
require 'curb'
require 'patron'
require 'typhoeus'
require 'eventmachine'
  require 'em/protocols/httpclient2'
require 'excon'
require 'httpclient'
require 'faraday'
require 'wrest'

url = ARGV.shift or raise "URL must be given"
url = URI.parse(url)
url_str = url.to_s
threads = 1
number = 10

jruby = defined?(JRUBY_VERSION)

targets = [
  :net_http,
  :net2_http,
  :open_uri,
  :httparty,
  :rest_client,
  :right_http_connection,
  :rufus_verbs,
  !jruby ? :curb : nil,
  !jruby ? :typhoeus : nil,
  # Java version looks to have threading issue
  (RUBY_VERSION > "1.9" or (jruby and threads == 1)) ? :eventmachine : nil,
  :excon,
  :httpclient,
  !jruby ? :faraday : nil,
  :faraday_net_http,
  :wrest
].compact

# Compare httpclient 50 threads vs EM 50 concurrency.
# threads = 50; number = 1; targets = [:httpclient]
# threads = 1; number = 50; targets = [:eventmachine]

def do_threads(number)
  if number == 1
    yield
  else
    number.times.map {
      Thread.new {
        results << yield
      }
    }.each(&:join)
  end
end

class NullLogger
  def <<(*arg)
  end

  def method_missing(msg_id, *a, &b)
  end
end
null_logger = NullLogger.new

Benchmark.bmbm do |bm|
  if targets.include?(:net_http)
    bm.report(' 1. net/http') do
      do_threads(threads) {
        c = Net::HTTP.new(url.host, url.port)
        c.start
        result = number.times.map {
          c.get(url.path).read_body.bytesize
        }
        c.finish
        result
      }
    end
  end

  if targets.include?(:open_uri)
    bm.report(' 2. open-uri') do
      do_threads(threads) {
        number.times.map {
          open(url) { |f|
            f.read.bytesize
          }
        }
      }
    end
  end

  if targets.include?(:httparty)
    bm.report(' 3. httparty') do
      do_threads(threads) {
        c = Class.new
        c.instance_eval { include HTTParty }
        number.times.map {
          c.get(url_str).body.bytesize
        }
      }
    end
  end

  if targets.include?(:rest_client)
    bm.report(' 4. rest-client') do
      do_threads(threads) {
        number.times.map {
          RestClient.get(url_str).bytesize
        }
      }
    end
  end

  if targets.include?(:right_http_connection)
    bm.report(' 5. right_http_connection') do
      do_threads(threads) {
        conn = Rightscale::HttpConnection.new(:logger => null_logger)
        result = number.times.map {
          req = {
            :request => Net::HTTP::Get.new(url.path),
            :server => url.host,
            :port => url.port,
            :protocol => url.scheme
          }
          conn.request(req).body.bytesize
        }
        conn.finish
        result
      }
    end
  end

  if targets.include?(:rufus_verbs)
    class RufusVerbsClient
      include Rufus::Verbs
      def run(params)
        get(params)
      end
    end

    bm.report(' 6. rufus-verbs') do
      do_threads(threads) {
        c = RufusVerbsClient.new
        number.times.map {
          c.run(:uri => url).body.bytesize
        }
      }
    end
  end

  if targets.include?(:curb)
    bm.report(' 7. curb') do
      do_threads(threads) {
        number.times.map {
          Curl::Easy.http_get(url.to_s).body_str.bytesize
        }
      }
    end
  end

  if targets.include?(:typhoeus)
    bm.report(' 8. typhoeus') do
      do_threads(threads) {
        number.times.map {
          Typhoeus::Request.get(url_str).body.bytesize
        }
      }
    end
  end

  if targets.include?(:eventmachine)
    bm.report(' 9. eventmachine/httpclient2') do
      EM.run do
        query = {}
        done = false
        do_threads(threads) {
          host, port = url.host, url.port
          path = url.path
          requests = 0
          number.times.map {
            client = EM::Protocols::HttpClient2.connect(host, port)
            req = client.get(url.path)
            query[req] = req
            req.callback {
              req.content.size
              query.delete(req)
              EM.stop if done && query.empty?
            }
          }
        }
        done = true
      end
    end
  end

  if targets.include?(:excon)
    bm.report('10. excon') do
      c = HTTPClient.new
      do_threads(threads) {
        number.times.map {
          Excon.get(url_str).body.bytesize
        }
      }
      c.reset_all
    end
  end

  if targets.include?(:httpclient)
    bm.report('11. httpclient') do
      c = HTTPClient.new
      do_threads(threads) {
        number.times.map {
          c.get(url).body.bytesize
        }
      }
    end
  end

  if targets.include?(:faraday)
    bm.report('12. faraday(typhoeus)') do
      do_threads(threads) {
        conn = Faraday.new(:url => (url + "/").to_s) { |builder|
          builder.adapter :typhoeus
        }
        number.times.map {
          conn.get(url.path).body.bytesize
        }
      }
    end
  end

  if jruby
    # Hit 1 time before to avoid autoload concurrency problem.
    Faraday.new(:url => (url + "/").to_s) { |builder|
      builder.adapter :net_http
    }.get(url.path)
  end

  if targets.include?(:faraday_net_http)
    bm.report('13. faraday(net/http)') do
      do_threads(threads) {
        conn = Faraday.new(:url => (url + "/").to_s) { |builder|
          builder.adapter :net_http
        }
        number.times.map {
          conn.get(url.path).body.bytesize
        }
      }
    end
  end

  if targets.include?(:wrest)
    Wrest.use_native!
    Wrest.logger = null_logger
    bm.report('14. wrest(net/http)') do
      do_threads(threads) {
        number.times.map {
          url.to_s.to_uri.get.body.bytesize
        }
      }
    end
  end
end
