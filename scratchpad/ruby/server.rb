require 'socket'

class SelectorStrategy
  attr_reader :enumerable, :current_index

  def initialize(enumerable)
    @enumerable = enumerable
    @current_index = 0
  end

  def tick
    if @current_index < @enumerable.size - 1
      @current_index += 1
      return @current_index
    else
      @current_index = 0
    end
    nil
  end

  def increment
    tick
    @current_index
  end
end

class NonBlockServer
  MAX_READ_SIZE = 10

  attr_reader :clients, :server

  def initialize(port)
    @server = TCPServer.new(port)
    @clients = []
    @reader_selector = SelectorStrategy.new(@clients)
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
    rescue Errno::Errno::ECONNABORTED, Errno::ECONNRESET
      debug "connection aborted 1"
    rescue Exception => e
      p e
    end
  end

  def try_reads
    client = nil
    begin
      client = clients[@reader_selector.current_index]
      response = client.recv_nonblock(1)
      disconnect(client) if response[0].to_s == ""

      debug "read from #{@reader_selector.current_index}, response: |#{response[0]}|"
      @reader_selector.increment
    rescue Errno::EAGAIN, Errno::EWOULDBLOCK
      retry unless @reader_selector.tick.nil?
    rescue Errno::ECONNABORTED, Errno::ECONNRESET
      debug "haven't received a Errno::ECONNABORTED or Errno::ECONNRESET yet.  TODO: Handle this correctly"
    end
  end

  def debug(message)
    puts "[debug] " + message
  end

  def disconnect(client)
    debug "disconnecting #{client}"
    begin
      clients.delete_if { |c| c == client }
    ensure
      client.close
    end
  end

  server = NonBlockServer.new(8888)

  # TODO: Catch an interupt instead of while true
  while true
    server.try_accept
    server.try_reads
    sleep 0.001
  end
end