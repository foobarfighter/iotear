require 'socket'

module IOTear
  class Server
    attr_reader :socket, :reactors, :clients 

    def initialize(port, options = nil)
      @socket = TCPServer.new(port)
      @reactors = {}
      @clients = []
    end

    def stop
      socket.close
    end

    def on_connect(&block)
      add_reactor(:connect, block)
    end

    def on_disconnect(&block)
      add_reactor(:disconnect, block)
    end

    def on_message(&block)
      add_reactor(:message, block)
    end

    def on_write_success(&block)
      add_reactor(:write_success, block)
    end

    def add_reactor(event, proc)
      @reactors[event] = [] unless @reactors.has_key?(event)
      @reactors[event] << proc
      proc
    end

    def remove_reactor(event, proc)
      @reactors[event].delete_if { |reactor_proc| reactor_proc == proc } if @reactors.has_key?(event) 
    end

    def trigger(event, *args)
      if @reactors[event]
        @reactors[event].each { |block| block.call(*args) }
      end
    end
  end
end