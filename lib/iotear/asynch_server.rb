require "#{File.dirname(__FILE__)}/server"
require "#{File.dirname(__FILE__)}/selector"

module IOTear
  class AsynchServer < Server
    def initialize(port, options = nil)
      super(port)
    end

    def run
    end

    def poll_accept
      begin
        client_socket, client_sockaddr = socket.accept_nonblock
        clients << (client = Client.new(client_socket, client_sockaddr))
        trigger(:connect, client)
      rescue Errno::EAGAIN, Errno::EWOULDBLOCK
        IO.select([socket])
        retry
      end
    end

    def poll_read
    end

    def poll_write
    end
  end
end