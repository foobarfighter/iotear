module IOTear
  class Client
    attr_reader :socket, :in_buffer

    def initialize(socket, sockaddr)
      @socket = socket
      @in_buffer = []
    end

    def readable?
      @in_buffer.size > 0
    end

    def read
      @in_buffer.shift if readable?
    end

    def write_in(block)
      @in_buffer << block
    end
  end
end