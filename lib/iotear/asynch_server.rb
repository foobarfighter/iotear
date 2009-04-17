require "#{File.dirname(__FILE__)}/server"

module IOTear
  class AsynchServer < Server
    def initialize(port, options = nil)
      super(port)
    end

    def run
    end

    def poll_accept
    end
  end
end