require 'webrick/httpproxy.rb'
require 'stringio'
require 'logger'

class ProxyServer < WEBrick::HTTPProxyServer
  def initialize(host, port, auth = false)
    @log = StringIO.new
    logger = Logger.new(@log)
    logger.level = Logger::Severity::DEBUG
    super(
      :BindAddress => host,
      :Port => port,
      :Logger => logger,
      :AccessLog => [],
      :ProxyAuthProc => auth ? proxy_auth_proc : nil
    )
    @server_thread = start_server_thread(self)
  end

  def log
    @log.string
  end

  def shutdown
    super
  end

private

  def proxy_auth_proc
    htpasswd = File.join(File.dirname(__FILE__), 'fixture', 'htpasswd')
    htpasswd_userdb = WEBrick::HTTPAuth::Htpasswd.new(htpasswd)
    proxy_basic_auth = WEBrick::HTTPAuth::ProxyBasicAuth.new(
      :Algorithm => 'MD5',
      :Realm => 'auth',
      :UserDB => htpasswd_userdb
    )
    proxy_basic_auth.method(:authenticate).to_proc
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
end
