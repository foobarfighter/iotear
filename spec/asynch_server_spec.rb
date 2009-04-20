require "#{File.dirname(__FILE__)}/spec_helper"

describe IOTear::AsynchServer do
  attr_reader :expected_port, :test_client
  before do
    @expected_port = 8888
    @test_client = TestClient.new(expected_port)
  end

  describe "#initialize" do
    it "descends from the Server class and calls Server#initialize" do
      server = IOTear::AsynchServer.new(expected_port)
      # This is a pretty weak test for testing that super was called
      server.socket.should_not be_nil
      server.stop
    end

    it "creates a new #reader_selector" do
      server = IOTear::AsynchServer.new(expected_port)
      server.reader_selector.should_not be_nil
      server.reader_selector.enumerable.should == server.clients
      server.stop
    end
  end

  describe "#poll_accept" do
    attr_reader :server
    before do
      @server = IOTear::AsynchServer.new(expected_port)
    end

    after do
      begin
        server.stop
      rescue IOError => e
      end
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
    attr_reader :server
    before do
      @server = IOTear::AsynchServer.new(expected_port)
    end

    after do
      server.stop
    end

    describe "when there are Clients" do
      before do
        test_client.connect.should be_connected
        server.poll_accept
        server.clients.size.should == 1
      end

      it "uses recv_nonblock on the Client sockets" do
        mock(server.reader_selector.current.socket).recv_nonblock(IOTear::AsynchServer::BLOCK_SIZE)
        server.poll_read
      end

      context "reader selection" do
        describe "when a Client has been successfully read from" do
          before do
            test_client.write("0")
            server.poll_read
            server.reader_selector.current_index.should == 0
          end

          it "tries to read from the Client following the last successful read" do
            mock.proxy(server.reader_selector).get.times(1)
            TestClient.new(expected_port).connect.write("1")
            server.poll_accept
            server.poll_read
            server.reader_selector.current_index.should == 1
          end
        end

        describe "when all Clients have been checked for data" do
          attr_reader :expected_client_size
          before do
            TestClient.new(expected_port).connect.should be_connected
            TestClient.new(expected_port).connect.should be_connected
            server.poll_accept
            server.poll_accept
            @expected_client_size = 3
            server.clients.size.should == expected_client_size
          end

          it "it exits after attempting to read from all available Clients" do
            mock.proxy(server.reader_selector).get.times(expected_client_size)
            server.poll_read
          end
        end
      end

      context "connection events" do
      end

      context "message processing" do
        describe "when the message_block is an empty string" do
          it "disconnects the client" do
            mock.proxy(server).client_disconnected(server.clients[0])
            test_client.disconnect
            server.poll_read
          end
        end

        describe "when the message_block is not empty" do
          attr_reader :message_block1, :message_block2
          before do
            @message_block1 = "0"*IOTear::AsynchServer::BLOCK_SIZE
            @message_block2 = "1"*IOTear::AsynchServer::BLOCK_SIZE
            test_client.write(message_block1 + message_block2)
          end

          it "writes a message_block to the Client's input buffer" do
            expected_client = server.clients.first
            server.poll_read
            expected_client.should be_readable
            expected_client.in_buffer.size.should == 1

            server.poll_read
            expected_client.in_buffer.size.should == 2
            server.clients.first.in_buffer[0].should == message_block1
            server.clients.first.in_buffer[1].should == message_block2
          end

          it "fires the :connect reactor event" do
            mock(server).trigger(:message, anything, message_block1) { |event, client| client.should == server.clients.first }
            server.poll_read
          end
        end
      end
    end

    describe "when there are no Clients" do
      before do
        server.clients.should be_empty
      end

      it "returns as soon as possible" do
        mock(server.reader_selector).get.times(0)
        server.poll_read
      end
    end
  end
#
  #  describe "#poll_write" do
  #    describe "when there is no currently active block being written" do
  #      describe "when there is a Client that has a block to write" do
  #        # acts as block_in_progress begin
  #        it "trys to send some data to the Client"
  #        describe "when the block is partially sent" do
  #          it "fires the :partial_write reactor event"
  #        end
  #        describe "when the entire block is sent" do
  #          it "fires the :block_success reactor event"
  #          it "increments the writer_selector"
  #        end
  #        describe "when sending data is unsuccessful" do
  #          it "increments the writer_selector"
  #          describe "when the Client was disconnected" do
  #            it "disconnects the Client"
  #          end
  #          describe "when the Client was not ready" do
  #            it "increments the writer_selector"
  #          end
  #        end
  #        # acts as block_in_progress end
  #      end
  #      describe "when no Client is found that has a block to write" do
  #        it "increments the writer_selector"
  #      end
  #    end
  #    describe "when there is an active block being written" do
  #      it "acts as a block_in_progress"
  #    end
  #  end
  #
  #  describe "#disconnect" do
  #    it "removes the unregisters the Client"
  #    it "closes the Client's socket"
  #  end
end