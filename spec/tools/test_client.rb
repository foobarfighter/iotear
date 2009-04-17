class TestClient
  def initialize(connect_port)
    begin
      @socket = TCPSocket.new("localhost", 8888)
      @connected = true
    rescue Exception => e
      @connected = false
    end
  end

  def connected?
    @connected
  end

  def disconnect
    @socket.close
  end
end