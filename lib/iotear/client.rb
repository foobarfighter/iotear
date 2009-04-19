module IOTear
  class Client
    attr_reader :socket

    def initialize(socket, sockaddr)
      @socket = socket
    end
  end
end