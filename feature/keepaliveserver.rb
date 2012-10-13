# -*- encoding: utf-8 -*-

require 'socket'


class KeepAliveServer
  def initialize(host)
    @server = TCPServer.open(host, 0)
    @server_thread = Thread.new {
      sock = @server.accept
      create_keepalive_thread(sock)
    }
    @url = "http://#{host}:#{@server.addr[1]}/"
  end

  def url
    @url
  end

  def shutdown
    @server.close
    @server_thread.join
  end

private

  def create_keepalive_thread(sock)
    Thread.new {
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

if $0 == __FILE__
  server = KeepAliveServer.new(ARGV.shift || 'localhost')
  puts server.url
  sleep
end
