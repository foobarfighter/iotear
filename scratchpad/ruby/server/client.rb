class Client
  attr_reader :uuid, :socket

  def initialize(socket)
    @socket = socket
    @uuid = UUID.generate
    @in_buffer = []
    @out_buffer = []
  end

  def can_read?
    @in_buffer.size > 0
  end

  def writes_pending?
    @out_buffer.size > 0
  end

  def read
    @in_buffer.shift if can_read?
  end

  def <<(block)
    @out_buffer << block
  end

  def write_in(block)
    @in_buffer << block
  end

  def read_out
    @out_buffer.shift if writes_pending?
  end
end