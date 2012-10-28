require 'uri'
require 'benchmark'

url = ARGV.shift or raise "URL must be given"
threads = ARGV.shift.to_i
number = ARGV.shift.to_i
block = ARGV
url = URI.parse(url)
url_str = url.to_s

jruby = defined?(JRUBY_VERSION)

targets = [
  :net_http,
  :open_uri,
  :httparty,
  :mechanize,
  :rest_client,
  :restfulie,
  :rufus_verbs,
  :em_http_request,
  :excon,
  :httpclient,
  !jruby ? :curb : nil,
  !jruby ? :curb_multi : nil,
  !jruby ? :patron : nil,
  :faraday,
  :httpi,
  :weary,
  :wrest
].compact

unless block.empty?
  targets = block.map { |e| targets[e.to_i - 1] }
end

# Compare httpclient 50 threads vs EM 50 concurrency.
# threads = 50; number = 1; targets = [:httpclient]
# threads = 1; number = 50; targets = [:eventmachine]

def do_threads(number)
  if number == 1
    yield
  else
    number.times.map {
      Thread.new {
        yield
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
    require 'net/http'
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
    require 'open-uri'
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
    require 'httparty'
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

  if targets.include?(:mechanize)
    require 'mechanize'
    bm.report(' 4. mechanize') do
      do_threads(threads) {
        c = Mechanize.new
        c.conditional_requests = false # disable page cache for benchmark
        number.times.map {
          c.get(url).content.bytesize
        }
      }
    end
  end

  if targets.include?(:rest_client)
    require 'rest-client'
    bm.report(' 5. rest-client') do
      do_threads(threads) {
        number.times.map {
          RestClient.get(url_str).bytesize
        }
      }
    end
  end

  if targets.include?(:restfulie)
    require 'restfulie'
    Restfulie::Common::Logger.logger.level = Logger::UNKNOWN # disable
    # To avoid autoload MT-unsafe issue
    Restfulie.at(url).get!
    bm.report(' 6. restfulie') do
      do_threads(threads) {
        number.times.map {
          Restfulie.at(url).get!.body.bytesize
        }
      }
    end
  end

  if targets.include?(:rufus_verbs)
    require 'rufus-verbs'
    class RufusVerbsClient
      include Rufus::Verbs
      def run(params)
        get(params)
      end
    end

    bm.report(' 7. rufus-verbs') do
      do_threads(threads) {
        c = RufusVerbsClient.new
        number.times.map {
          c.run(:uri => url).body.bytesize
        }
      }
    end
  end

  if targets.include?(:em_http_request)
    require 'em-http'
    bm.report(' 8. em-http-request') do
      EM.run do
        query = {}
        done = false
        do_threads(threads) {
          number.times.map {
            req = EventMachine::HttpRequest.new(url).get
            query[req] = req
            req.callback do
              req.response.bytesize
              query.delete(req)
              EM.stop if done && query.empty?
            end
            req.errback { warn 'err' }
          }
        }
        done = true
      end
    end
  end

  if targets.include?(:excon)
    require 'excon'
    bm.report(' 9. excon') do
      do_threads(threads) {
        number.times.map {
          Excon.get(url_str).body.bytesize
        }
      }
    end
  end

  if targets.include?(:httpclient)
    require 'httpclient'
    bm.report('10. httpclient') do
      c = HTTPClient.new
      do_threads(threads) {
        number.times.map {
          c.get(url).body.bytesize
        }
      }
    end
  end

  if targets.include?(:curb)
    require 'curb'
    bm.report('11. curb(easy)') do
      do_threads(threads) {
        number.times.map {
          Curl::Easy.http_get(url.to_s).body_str.bytesize
        }
      }
    end
  end

  if targets.include?(:curb_multi)
    require 'curb'
    bm.report('12. curb(multi)') do
      do_threads(threads) {
        responses = []
        m = Curl::Multi.new
        number.times do |idx|
          responses[idx] = ''
          m.add(Curl::Easy.new(url_str) { |curl|
            curl.on_body { |data| responses[idx] << data; data.bytesize }
          })
        end
        m.perform
        responses.map { |e| e.bytesize }
      }
    end
  end

  if targets.include?(:patron)
    require 'patron'
    bm.report('13. patron') do
      do_threads(threads) {
        c = Patron::Session.new
        c.timeout = 20
        number.times.map {
          c.get(url).body.bytesize
        }
      }
    end
  end

  if targets.include?(:faraday)
    require 'faraday'
    bm.report('14. faraday(net/http)') do
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

  if targets.include?(:httpi)
    require 'httpi'
    HTTPI.logger.level = Logger::UNKNOWN # disable
    bm.report('15. httpi(httpclient)') do
      do_threads(threads) {
        number.times.map {
          HTTPI.get(url_str).body.bytesize
        }
      }
    end
  end

  if targets.include?(:weary)
    require 'weary'
    bm.report('16. weary') do
      h = Class.new(Weary::Client)
      domain = url.dup
      domain.path = '/'
      h.domain(domain.to_s)
      h.get :get, '{path}'
      c = h.new
      do_threads(threads) {
        number.times.map {
          c.get(:path => url.path.sub(/^\//, '')).perform.body.bytesize
        }
      }
    end
  end

  if targets.include?(:wrest)
    require 'wrest'
    Wrest.use_native!
    Wrest.logger = null_logger
    bm.report('17. wrest(net/http)') do
      do_threads(threads) {
        number.times.map {
          url_str.to_uri.get.body.bytesize
        }
      }
    end
  end
end
