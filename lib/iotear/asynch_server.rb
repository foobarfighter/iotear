require "#{File.dirname(__FILE__)}/server"
require "#{File.dirname(__FILE__)}/selector"
require "#{File.dirname(__FILE__)}/message_writer"

module IOTear
  class AsynchServer < Server
    BLOCK_SIZE = 1

    attr_reader :reader_selector, :writer_selector, :message_writer

    def initialize(port, options = nil)
      super(port)
      @reader_selector = Selector.new(clients)
      @writer_selector = Selector.new(clients)
      @message_writer = nil
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
      return unless clients.size > 0
      
      begin
        client = reader_selector.get
        message_block = client.socket.recv_nonblock(BLOCK_SIZE)
        return client_disconnected(client) if message_block.nil? || message_block == ""

        client.write_in(message_block)
        trigger(:message, client, message_block)
      rescue Errno::EAGAIN, Errno::EWOULDBLOCK
        retry unless reader_selector.last?
      end
    end

    def poll_write
      if message_writer.nil? || message_writer.finished?    
        client = writer_selector.find { |client| client.writes_pending? }
        @message_writer = MessageWriter.new(client, BLOCK_SIZE) unless client.nil?
      end

      if message_writer && !message_writer.finished?
        message_writer.send_nonblock
        trigger(:deliver, message_writer.client, message_writer.block) if message_writer.finished?
      end
    end

    def client_disconnected(client)
    end
  end
end