class BlockWriter

  def initialize(client, message_size)
    @client = client
    @out = @client.read_out
    @finished = false
    @message_size = message_size
    @sent_bytes = 0
  end

  def send_nonblock
    buffer = @out[@sent_bytes..@sent_bytes+@message_size-1]
    if buffer.nil? || buffer == ''
      @finished = true
    else
      @sent_bytes += @client.socket.write_nonblock(buffer)
    end
  end

  def finished?
    @finished
  end
end