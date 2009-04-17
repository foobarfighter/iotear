require "#{File.dirname(__FILE__)}/spec_helper"

describe IOTear::AsynchServer do
  attr_reader :expected_port
  before do
    @expected_port = 8888
  end

  describe "#initialize" do
    it "descends from the Server class and calls Server#initialize" do
      server = IOTear::AsynchServer.new(expected_port)
      # This is a pretty weak test for testing that super was called
      server.socket.should_not be_nil
    end
  end

  describe "#poll_accept" do
    describe "when there are no client sockets in the accept queue" do
      it "falls back to a blocking select to accept a new connection"
    end

    describe "when there are client sockets in the accept queue" do
      describe "when the accepted client socket is not already registered with the server" do
        it "registers the a new Client with the server"
        it "fires the :connect reactor event"
      end
    end
  end

  describe "#poll_read" do
    describe "when there are Clients" do
      it "attempts a recv_nonblock on the current Client socket"
      describe "when the recv_nonblock call throws an ReadNotReady state exception" do
        describe "when all Clients have been read" do
          it "does not attempt another recv_nonblock"
        end
        describe "when more Clients are left to read" do
          it "tries to read from another Client"
        end
      end
      describe "when the recv_nonblock call throws a ConnectionNotReady state exception" do
      end
      describe "when the recv_nonblock call returns a message_block" do
        it "increments the reader_selector for in preparation for the next read"
        describe "when the message_block is an empty string (signalling a disconnect)" do
          it "disconnects the Client"
        end
        describe "when the message_block contains data" do
          it "writes the message_block to the Clients input buffer"
        end
      end
    end
  end
end