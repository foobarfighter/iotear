require 'socket'
require 'server/block_writer'
require 'server/selector_strategy'
require 'server/client'
require 'rubygems'
require 'uuid'

class NonBlockServer
  BLOCK_SIZE = 10

  attr_reader :clients, :server

  def initialize(port)
    @server = TCPServer.new(port)
    @clients = []
    @reader_selector = SelectorStrategy.new(@clients)
    @block_writer = nil
    debug "server listening on #{port}"
  end

  def find_client(socket)
    clients.find { |client| client.socket == socket }
  end

  def try_accept
    begin
      client_socket, client_sockaddr = server.accept_nonblock
      @clients << Client.new(client_socket) unless find_client(client_socket)
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
    return unless clients.size > 0

    client = nil
    begin
      client = clients[@reader_selector.current_index]
      message_block = client.socket.recv_nonblock(BLOCK_SIZE)

      if message_block.to_s == ""
        disconnect(client)
      else
        debug "read from #{@reader_selector.current_index}, response: |#{message_block}|"
        client.write_in(message_block)
      end
      @reader_selector.increment
    rescue Errno::EAGAIN, Errno::EWOULDBLOCK
      retry unless @reader_selector.tick.nil?
    rescue Errno::ECONNABORTED, Errno::ECONNRESET
      debug "haven't received a Errno::ECONNABORTED or Errno::ECONNRESET yet.  TODO: Handle this correctly"
    end
  end

  def try_writes
    return unless clients.size > 0

    begin
      if @block_writer.nil? || @block_writer.finished?
        if client = clients.find { |client| client.writes_pending? }
          @block_writer = BlockWriter.new(client, BLOCK_SIZE)
          debug "writing block to #{client.uuid}"
        end
      end

      @block_writer.send_nonblock unless @block_writer.nil?
    rescue Errno::EAGAIN, Errno::EWOULDBLOCK
      #noop?
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
      client.socket.close
    end
  end
end
