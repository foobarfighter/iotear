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
      p e
    end
    self
  end

  def connected?
    @connected
  end

  def write(message)
    @socket.write(message)
    sleep 0.1
  end

  def disconnect
    @socket.close
    sleep 0.1    
  end
end