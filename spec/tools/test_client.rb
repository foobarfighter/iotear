class TestClient
  attr_reader :socket

  def initialize(connect_port)
    @port = connect_port
  end

  def connect
    begin
      @socket = TCPSocket.new("localhost", @port)
      @connected = true
    rescue Exception => e
      @connected = false
    end
    self
  end

  def connected?
    @connected
  end

  def disconnect
    @socket.close
  end
end