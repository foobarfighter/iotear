module IOTear
  class MessageWriter
    attr_reader :client, :block

    def initialize(client, message_size)
      @client = client
      @block = @client.read_out
      @finished = false
      @message_size = message_size
      @sent_bytes = 0
    end

    def send_nonblock
      buffer = @block[@sent_bytes..@sent_bytes+@message_size-1]
      if buffer.nil? || buffer == ''
        @finished = true
      else
        @sent_bytes += @client.socket.write_nonblock(buffer)
        @finished = true if @sent_bytes == @block.size
      end
    end

    def finished?
      @finished
    end
  end
end