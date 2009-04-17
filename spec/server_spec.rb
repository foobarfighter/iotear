require "#{File.dirname(__FILE__)}/spec_helper"

describe IOTear::Server do
  attr_reader :server, :expected_port
  before do
    @expected_port = 8888
    @server = IOTear::Server.new(expected_port)
  end

  after do
    begin
      server.stop
    rescue IOError
      # It's ok if the server was already stopped
    end
  end

  describe "#initialize" do
    it "creates a new TCPServer socket that listens on the expected_port" do
      server.socket.is_a?(TCPServer).should be_true
      test_client = TestClient.new(expected_port)
      test_client.should be_connected
      test_client.disconnect
    end

    it "intiailizes reactors as an empty hash" do
      server.reactors.should_not be_nil
    end
  end

  describe "#stop" do
    before do
      server.socket.should_not be_closed
    end

    it "closes its socket" do
      server.stop
      server.socket.should be_closed
    end
  end

  describe "#add_reactor" do
    it "adds a reactor Proc to the reactor array for the event" do
      server.add_reactor(:bogus1, Proc.new { })
      server.reactors[:bogus1].length.should == 1
    end

    it "returns a handle to the reactor Proc" do
      proc = server.add_reactor(:bogus2, Proc.new { true })
      server.reactors[:bogus2][0].should == proc
    end
  end

  describe "#remove_reactor" do
    attr_reader :reactor_to_remove, :reactor_to_keep

    describe "when the event is found" do
      before do
        @reactor_to_remove = server.add_reactor(:reactor_event, Proc.new { true })
        @reactor_to_keep = server.add_reactor(:reactor_event, Proc.new { true })
        server.reactors[:reactor_event].size.should == 2
      end

      it "removes the reactor" do
        server.remove_reactor(:reactor_event, reactor_to_remove)
        server.reactors[:reactor_event].size.should == 1
        server.reactors[:reactor_event][0].should == reactor_to_keep
      end
    end

    describe "when the event is not found" do
      it "does not error" do
        server.remove_reactor(:nonexistent_event, Proc.new { true })
      end
    end
  end

  describe "#on_connect" do
    it "registers a :connect event reactor Proc" do
      proc = server.on_connect { true }
      server.reactors[:connect][0].should == proc
    end
  end

  describe "#on_disconnect" do
    it "registers a :disconnect event reactor Proc" do
      proc = server.on_disconnect { true }
      server.reactors[:disconnect][0].should == proc
    end
  end

  describe "#on_message" do
    it "registers a :message event reactor Proc" do
      proc = server.on_message { true }
      server.reactors[:message][0].should == proc
    end
  end

  describe "#on_write_success" do
    it "registers a :write_success event reactor Proc" do
      proc = server.on_write_success { true }
      server.reactors[:write_success][0].should == proc
    end
  end
end