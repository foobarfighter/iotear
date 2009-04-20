require 'socket'
require 'server/block_writer'
require 'server/selector_strategy'
require 'server/client'
require 'rubygems'
require 'uuid'

class NonBlockServer
  BLOCK_SIZE = 4096
  DEBUG = false

  attr_reader :clients, :server

  def initialize(port)
    @server = TCPServer.new(port)
    @clients = []
    @reader_selector = SelectorStrategy.new(@clients)
    @block_writer = nil
    @handlers = {}
    info "server listening on #{port}"
    yield(self) if block_given?
  end

  def on_connect(&block)
    register_handler(:connect, block)
  end

  def on_disconnect(&block)
    register_handler(:disconnect, block)
  end

  def on_message(&block)
    register_handler(:message, block)
  end

  def on_write_success(&block)
    register_handler(:write_success, block)
  end

  def register_handler(event, block)
    @handlers[event] = [] unless @handlers.has_key?(event)
    @handlers[event] << block
  end

  def run_handlers(event, *args)
    if @handlers[event]
      @handlers[event].each { |block| block.call(*args) }
    end
  end

  def run  
    while true
      try_accept
      try_reads
      try_writes
      sleep 0.001
    end
  end

  def find_client(socket)
    clients.find { |client| client.socket == socket }
  end

  def try_accept
    begin
      client_socket, client_sockaddr = server.accept_nonblock
      unless find_client(client_socket)
        @clients << Client.new(client_socket)
        run_handlers :connect, @clients.last
      end
    rescue Errno::EAGAIN
      if clients.size == 0
        debug "no client is waiting, falling back to blocking select"
        IO.select([server])
        retry
      end
    rescue Errno::ECONNABORTED, Errno::ECONNRESET
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
        run_handlers(:message, client, message_block)
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
          @block_writer = MessageWriter.new(client, BLOCK_SIZE)
          debug "writing block to #{client.uuid}"
        end
      end

      if @block_writer && !@block_writer.finished?
        @block_writer.send_nonblock
        run_handlers(:write_success, @block_writer.client, @block_writer.block)
      end
    rescue Errno::EAGAIN, Errno::EWOULDBLOCK
      #noop?
    rescue Errno::ECONNABORTED, Errno::ECONNRESET
      debug "haven't received a Errno::ECONNABORTED or Errno::ECONNRESET yet.  TODO: Handle this correctly"
    end
  end

  def debug(message)
    puts "[debug] " + message if DEBUG
  end

  def info(message)
    puts "[info] " + message
  end

  def disconnect(client)
    debug "disconnecting #{client}"
    begin
      clients.delete_if { |c| c == client }
    ensure
      client.socket.close
    end
    run_handlers(:disconnect, client)
  end
end
