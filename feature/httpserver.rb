require 'webrick'
require 'logger'
require 'cgi'

class HTTPServer < WEBrick::HTTPServer
  Port = 17171

  def initialize(host, port)
    @logger = Logger.new(STDERR)
    @logger.level = Logger::Severity::FATAL
    super(
      :BindAddress => host,
      :Port => port,
      :Logger => @logger,
      :AccessLog => []
    )
    [:hello, :cookies, :redirect1, :redirect2, :redirect3, :redirect_self, :chunked, :largebody, :status, :compressed].each do |sym|
      self.mount(
	"/#{sym}",
	WEBrick::HTTPServlet::ProcHandler.new(method("do_#{sym}").to_proc)
      )
    end
    self.mount('/servlet', FeatureServlet.new(self))
    self.mount('/basic_auth', WEBrick::HTTPServlet::ProcHandler.new(method(:do_basic_auth).to_proc))
    self.mount('/digest_auth', WEBrick::HTTPServlet::ProcHandler.new(method(:do_digest_auth).to_proc))
    self.mount('/digest_sess_auth', WEBrick::HTTPServlet::ProcHandler.new(method(:do_digest_sess_auth).to_proc))
    htpasswd = File.join(File.dirname(__FILE__), 'fixture', 'htpasswd')
    htpasswd_userdb = WEBrick::HTTPAuth::Htpasswd.new(htpasswd)
    htdigest = File.join(File.dirname(__FILE__), 'fixture', 'htdigest')
    htdigest_userdb = WEBrick::HTTPAuth::Htdigest.new(htdigest)
    @basic_auth = WEBrick::HTTPAuth::BasicAuth.new(
      :Realm => 'auth',
      :UserDB => htpasswd_userdb
    )
    @digest_auth = WEBrick::HTTPAuth::DigestAuth.new(
      :Algorithm => 'MD5',
      :Realm => 'auth',
      :UserDB => htdigest_userdb
    )
    @digest_sess_auth = WEBrick::HTTPAuth::DigestAuth.new(
      :Algorithm => 'MD5-sess',
      :Realm => 'auth',
      :UserDB => htdigest_userdb
    )
    @server_thread = start_server_thread(self)
  end

private

  def start_server_thread(server)
    t = Thread.new {
      Thread.current.abort_on_exception = true
      server.start
    }
    while server.status != :Running
      Thread.pass
      unless t.alive?
	t.join
	raise
      end
    end
    t
  end

  def do_cookies(req, res)
    req.cookies.each do |cookie|
      c = WEBrick::Cookie.new(cookie.name, (cookie.value.to_i + 1).to_s)
      c.domain = 'localhost'
      c.expires = Time.now + 60 * 60 * 24 * 365
      res.cookies << c
    end
  end

  def do_hello(req, res)
    res['content-type'] = 'text/html'
    res.body = "hello"
  end

  def do_redirect1(req, res)
    res.set_redirect(WEBrick::HTTPStatus::MovedPermanently, req.request_uri + "/hello") 
  end

  def do_redirect2(req, res)
    res.set_redirect(WEBrick::HTTPStatus::TemporaryRedirect, req.request_uri + "/redirect1")
  end

  def do_redirect3(req, res)
    res.set_redirect(WEBrick::HTTPStatus::Found, req.request_uri + "/redirect2") 
  end

  def do_redirect_self(req, res)
    res.set_redirect(WEBrick::HTTPStatus::Found, req.request_uri + "/redirect_self") 
  end

  def do_chunked(req, res)
    res.chunked = true
    piper, pipew = IO.pipe
    res.body = piper
    pipew << req.query['msg']
    pipew.close
  end

  def do_largebody(req, res)
    res['content-type'] = 'text/html'
    res.body = "a" * 1000 * 1000
  end

  # compression result of 'hello'.
  GZIP_CONTENT = "\x1f\x8b\x08\x00\x1a\x96\xe0\x4c\x00\x03\xcb\x48\xcd\xc9\xc9\x07\x00\x86\xa6\x10\x36\x05\x00\x00\x00"
  DEFLATE_CONTENT = "\x78\x9c\xcb\x48\xcd\xc9\xc9\x07\x00\x06\x2c\x02\x15"
  GZIP_CONTENT.force_encoding('BINARY') if GZIP_CONTENT.respond_to?(:force_encoding)
  DEFLATE_CONTENT.force_encoding('BINARY') if DEFLATE_CONTENT.respond_to?(:force_encoding)
  def do_compressed(req, res)
    if req.accept_encoding.include?('gzip') && req.query['enc'] == 'gzip'
      res['content-encoding'] = 'gzip'
      res.body = GZIP_CONTENT
    elsif req.accept_encoding.include?('deflate') && req.query['enc'] == 'deflate'
      res['content-encoding'] = 'deflate'
      res.body = DEFLATE_CONTENT
    else
      res.body = 'not compressed'
    end
  end

  def do_status(req, res)
    res.status = req.query['status'].to_i
  end

  def do_basic_auth(req, res)
    @basic_auth.authenticate(req, res)
    res['content-type'] = 'text/plain'
    res.body = 'basic_auth OK'
  end

  def do_digest_auth(req, res)
    @digest_auth.authenticate(req, res)
    res['content-type'] = 'text/plain'
    res['x-query'] = req.body
    res.body = 'digest_auth OK' + req.query_string.to_s
  end

  def do_digest_sess_auth(req, res)
    @digest_sess_auth.authenticate(req, res)
    res['content-type'] = 'text/plain'
    res['x-query'] = req.body
    res.body = 'digest_sess_auth OK' + req.query_string.to_s
  end

  class FeatureServlet < WEBrick::HTTPServlet::AbstractServlet
    def get_instance(*arg)
      self
    end

    def do_HEAD(req, res)
      res["x-head"] = 'head'	# use this for test purpose only.
      res["x-query"] = query_response(req)
    end

    def do_GET(req, res)
      res.body = 'get'
      res["x-query"] = query_response(req)
    end

    def do_POST(req, res)
      res.body = 'post,' + req.body.to_s
      res["x-query"] = body_response(req)
    end

    def do_PUT(req, res)
      req.continue
      res["x-query"] = body_response(req)
      param = WEBrick::HTTPUtils.parse_query(req.body) || {}
      res["x-size"] = (param['txt'] || '').size
      res.body = param['txt'] || 'put'
    end

    def do_DELETE(req, res)
      res.body = 'delete'
    end

    def do_OPTIONS(req, res)
      # check RFC for legal response.
      res.body = 'options'
    end

    def do_PROPFIND(req, res)
      res.body = 'propfind'
    end

    def do_PROPPATCH(req, res)
      res.body = 'proppatch'
      res["x-query"] = body_response(req)
    end

    def do_TRACE(req, res)
      # client SHOULD reflect the message received back to the client as the
      # entity-body of a 200 (OK) response. [RFC2616]
      res.body = 'trace'
      res["x-query"] = query_response(req)
    end

  private

    def query_response(req)
      query_escape(WEBrick::HTTPUtils.parse_query(req.query_string))
    end

    def body_response(req)
      query_escape(WEBrick::HTTPUtils.parse_query(req.body))
    end

    def query_escape(query)
      escaped = []
      query.sort_by { |k, v| k }.collect do |k, v|
	v.to_ary.each do |ve|
	  escaped << CGI.escape(k) + '=' + CGI.escape(ve)
	end
      end
      escaped.join('&')
    end
  end

  class KeepAliveServer
    def initialize(host)
      @server = TCPServer.open(host, 0)
      @server_thread = Thread.new {
        Thread.abort_on_exception = true
        sock = @server.accept
        create_keepalive_thread(sock)
      }
      @url = "http://#{host}:#{@server.addr[1]}/"
    end

    def url
      @url
    end

    def close
      @server.close
      @server_thread.join
    end

  private

    def create_keepalive_thread(sock)
      Thread.new {
        Thread.abort_on_exception = true
        5.times do
          req = sock.gets
          while line = sock.gets
            break if line.chomp.empty?
          end
          case req
          when /chunked/
            sock.write("HTTP/1.1 200 OK\r\n")
            sock.write("Transfer-Encoding: chunked\r\n")
            sock.write("\r\n")
            sock.write("1a\r\n")
            sock.write("abcdefghijklmnopqrstuvwxyz\r\n")
            sock.write("10\r\n")
            sock.write("1234567890abcdef\r\n")
            sock.write("0\r\n")
            sock.write("\r\n")
          else
            sock.write("HTTP/1.1 200 OK\r\n")
            sock.write("Content-Length: 5\r\n")
            sock.write("\r\n")
            sock.write("12345")
          end
        end
        sock.close
      }
    end
  end
end
