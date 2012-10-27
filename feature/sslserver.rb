require 'webrick/https'
require 'logger'
require 'cgi'

class SSLServer < WEBrick::HTTPServer
  DIR = File.dirname(__FILE__)

  def initialize(host, port)
    @logger = Logger.new(STDERR)
    @logger.level = Logger::Severity::FATAL
    super(
      :BindAddress => host,
      :Logger => logger,
      :Port => port,
      :AccessLog => [],
      :DocumentRoot => DIR,
      :SSLEnable => true,
      :SSLCACertificateFile => File.join(DIR, 'fixture', 'ca.pem'),
      :SSLCertificate => cert('server.cert'),
      :SSLPrivateKey => key('server.key'),
      :SSLVerifyClient => nil, #OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT|OpenSSL::SSL::VERIFY_PEER,
      :SSLClientCA => nil,
      :SSLCertName => nil
    )
    [
      :hello
    ].each do |sym|
      self.mount(
	"/#{sym}",
	WEBrick::HTTPServlet::ProcHandler.new(method("do_#{sym}").to_proc)
      )
    end
    @server_thread = start_server_thread(self)
  end

  def shutdown
    super
    @server_thread.join if RUBY_ENGINE == 'rbx'
  end

private

  def cert(filename)
    OpenSSL::X509::Certificate.new(File.read(File.join(DIR, 'fixture', filename)))
  end

  def key(filename)
    OpenSSL::PKey::RSA.new(File.read(File.join(DIR, 'fixture', filename)))
  end

  def start_server_thread(server)
    t = Thread.new {
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

  def do_hello(req, res)
    res['content-type'] = 'text/plain'
    res.body = "hello ssl"
  end
end
