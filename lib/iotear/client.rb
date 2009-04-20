module IOTear
  class Client
    attr_reader :socket, :in_buffer

    def initialize(socket, sockaddr)
      @socket = socket
      @in_buffer = []
      @out_buffer = []
    end

    def writes_pending?
      @out_buffer.size > 0
    end

    def <<(block)
      @out_buffer << block
    end

    def read_out
      @out_buffer.shift if writes_pending?
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