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
      server.stop
    end
  end

  describe "#poll_accept" do
    attr_reader :server
    before do
      @server = IOTear::AsynchServer.new(expected_port)
    end

    after do
      server.stop
    end

    describe "when there are no client sockets in the accept queue" do
      it "falls back to a blocking select to accept a new connection" do
        mock(IO).select([server.socket]) { raise "expected error" }

        begin
          server.poll_accept
        rescue Exception => e
          raise e if e.message != "expected error"
        end
      end
    end

    describe "when there are client sockets in the accept queue" do
      attr_reader :mutex, :test_client
      before do
        @mutex = Mutex.new
        thread = Thread.new do
          mutex.synchronize do
            server.poll_accept
          end
        end
        poll_for_sleep thread
        @test_client = TestClient.new(expected_port)
      end

      it "registers the a new Client with the server" do
        server.clients.should be_empty
        test_client.connect.should be_connected

        mutex.synchronize do
          server.clients.length.should == 1
        end
      end

      it "fires the :connect reactor event" do
        mock(server).trigger(:connect, anything) { |event, client| client.should == server.clients[0] }
        test_client.connect
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

  describe "#poll_write" do
    describe "when there is no currently active block being written" do
      describe "when there is a Client that has a block to write" do
        # acts as block_in_progress begin
        it "trys to send some data to the Client"
        describe "when the block is partially sent" do
          it "fires the :partial_write reactor event"
        end
        describe "when the entire block is sent" do
          it "fires the :block_success reactor event"
          it "increments the writer_selector"
        end
        describe "when sending data is unsuccessful" do
          it "increments the writer_selector"
          describe "when the Client was disconnected" do
            it "disconnects the Client"
          end
          describe "when the Client was not ready" do
            it "increments the writer_selector"
          end
        end
        # acts as block_in_progress end
      end
      describe "when no Client is found that has a block to write" do
        it "increments the writer_selector"
      end
    end
    describe "when there is an active block being written" do
      it "acts as a block_in_progress"
    end
  end

  describe "#disconnect" do
    it "removes the unregisters the Client"
    it "closes the Client's socket"
  end
end