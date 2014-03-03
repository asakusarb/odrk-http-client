require 'uri'
require 'test/unit'
require 'tempfile'
require File.expand_path('./httpserver', File.dirname(__FILE__))
require File.expand_path('./sslserver', File.dirname(__FILE__))
require File.expand_path('./proxyserver', File.dirname(__FILE__))

$host = 'localhost'
$port = 17171
$ssl_port = 17172
$proxy_port = 17173

class OdrkHTTPClientTestCase < Test::Unit::TestCase
  DIR = File.dirname(__FILE__)

  def setup
    @server = HTTPServer.new($host, $port)
    @ssl_server = nil
    @proxy_server = nil
    @url = "http://#{$host}:#{$port}/"
    @ssl_url = "https://localhost:#{$ssl_port}/"
    @ssl_fake_url = "https://127.0.0.1:#{$ssl_port}/"
    @proxy_url = "http://#{$host}:#{$proxy_port}/"
  end

  def teardown
    @server.shutdown
    @ssl_server.shutdown if @ssl_server
    @proxy_server.shutdown if @proxy_server
  end

  def setup_sslserver
    @ssl_server = SSLServer.new($host, $ssl_port)
  end

  def setup_proxyserver(auth = false)
    @proxy_server = ProxyServer.new($host, $proxy_port, auth)
  end

  def url_with_auth(url, user, password)
    url = URI.parse(url.to_s)
    url.user = user
    url.password = password
    url.to_s
  end

  def issue_crl(revoke_info, issuer_cert, issuer_key)
    now = Time.now
    crl = OpenSSL::X509::CRL.new
    crl.issuer = issuer_cert.subject
    crl.version = 1
    crl.last_update = now
    crl.next_update = now + 1800
    revoke_info.each do |serial, time, reason_code|
      revoked = OpenSSL::X509::Revoked.new
      revoked.serial = serial
      revoked.time = time
      enum = OpenSSL::ASN1::Enumerated(reason_code)
      ext = OpenSSL::X509::Extension.new("CRLReason", enum)
      revoked.add_extension(ext)
      crl.add_revoked(revoked)
    end
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.issuer_certificate = issuer_cert
    ef.crl = crl
    crlnum = OpenSSL::ASN1::Integer(1)
    crl.add_extension(OpenSSL::X509::Extension.new("crlNumber", crlnum))
    crl.sign(issuer_key, OpenSSL::Digest::SHA1.new)
    crl
  end

  def cert(filename)
    OpenSSL::X509::Certificate.new(File.read(File.join(DIR, 'fixture', filename)))
  end

  def key(filename, password = nil)
    OpenSSL::PKey::RSA.new(File.read(File.join(DIR, 'fixture', filename)), password)
  end
end

