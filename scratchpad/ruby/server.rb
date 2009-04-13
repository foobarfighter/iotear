require 'socket'

class NonBlockServer
  MAX_READ_SIZE = 10

  attr_reader :clients, :server

  def initialize(port)
    @server = TCPServer.new(port)
    @clients = []
    @last_index = 0
    debug "server listening on #{port}"
  end

  def try_accept
    begin
      client_socket, client_sockaddr = server.accept_nonblock
      @clients << client_socket unless clients.include?(client_socket)
    rescue Errno::EAGAIN
      if clients.size == 0
        debug "no client is waiting, falling back to blocking select"
        IO.select([server])
        retry
      end
    end
  end

  def try_reads
    begin
      response = clients[@last_index].recv_nonblock(1)
      debug "read from #{@last_index}, response: #{response[0]}"
      increment_index
    rescue Errno::EAGAIN
      retry unless tick_index.nil?
    end
  end

  def tick_index
    @last_index ||= 0
    if @last_index < clients.size - 1
      @last_index += 1
      return @last_index
    else
      @last_index = 0
    end
    nil
  end

  def increment_index
    tick_index
    @last_index
  end

  def debug(message)
    puts "[debug] " + message
  end
end

server = NonBlockServer.new(8888)

# TODO: Catch an interupt instead of while true
while true
  server.try_accept
  server.try_reads
end
