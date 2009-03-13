require "#{File.dirname(__FILE__)}/spec_helper.rb"
require 'thread'

describe ThreadPool do
  attr_reader :thread_count, :pool, :thread_names

  def kill_threads(pool)
    return if pool.threads.nil?

    pool.threads.each do |thread|
      Thread.kill(thread)
    end
  end

  before do
    Thread.abort_on_exception = true

    @thread_count = 10
    @pool = ThreadPool.new(@thread_count)
    @thread_names = pool.threads.collect { |thread| thread[:name] }
    thread_names.size.should == thread_count
  end

  after do
    kill_threads(pool)
  end

  context "#initialize" do

    it "sets the threads" do
      pool.threads.should_not be_nil
      pool.threads.size.should == thread_count
    end

    it "sets the waiters" do
      pool.waiters.should_not be_nil
      pool.waiters.size.should == thread_count
    end

    it "creates n number of sleeping threads" do
      pool.threads.find_all { |thread| thread.status == "sleep" }.size.should == thread_count
    end

    describe "when a thread prefix is passed" do
      before do
        @pool = ThreadPool.new(@thread_count, :thread_prefix => "foo")
      end

      after do
        kill_threads(pool)
      end

      it "gives each thread a default name" do
        pool.threads.each do |thread|
          thread[:name].should match(/foo\d+/)
        end
      end
    end

    describe "when no thread prefix is passed" do
      it "gives each thread a default name" do
        @pool = ThreadPool.new(@thread_count)
        pool.threads.each do |thread|
          thread[:name].should match(/threadpool\d+/)
        end
      end
    end
  end

  context "#kill_all!" do
    attr_reader :outside_thread

    before do
      @outside_thread = Thread.new { sleep 10 }
    end

    after do
      Thread.kill(@outside_thread)
    end

    it "kills all threads that belong to the thread pool" do
      threads = pool.threads.dup
      pool.kill_all!
      threads.each { |thread| [false, "aborting"].should include(thread.status) }
      ["sleep", "run"].should include(outside_thread.status)
    end

    it "sets pool.threads to nil" do
      pool.kill_all!
      pool.threads.should be_nil
    end

    it "sets pool.waiters to nil" do
      pool.kill_all!
      pool.waiters.should be_nil
    end
  end

  context "#waiting?" do
    describe "when there are no threads left to service the task" do
      it "returns true" do
        (1..thread_count).each do |i|
          pool.process { sleep 10 }
        end
        pool.should be_waiting
      end
    end

    describe "when there are threads left to service the task" do
      it "returns true" do
        waiter_count = 2
        (1..(thread_count - waiter_count)).each do |i|
          pool.process { sleep 10 }
        end
        pool.waiters.size.should == waiter_count
        pool.should_not be_waiting
      end
    end
#    describe "when there are no thread waiting" do
    #      (1..pool.threads.size).each do |i|
    #        pool.process { sleep 10 }
    #      end
    #      pool.should_not be_waiting
    #    end

    #      waiter_count = 2
    #      (1..pool.threads.size-waiter_count).each do |i|
    #        pool.process { sleep 10 }
    #      end
    #      pool.waiters.should == waiter_count
    #      pool.should be_waiting
    #    end
  end


  context "#process" do
    describe "when there are threads waiting" do
      attr_reader :mutex, :cv, :main_thread, :run_count, :threads_working

      before do
        @mutex = Mutex.new
        @cv = ConditionVariable.new
        @run_count = 2
        @main_thread = Thread.current
        @threads_working = 0

        run_count = 2
        mutex.synchronize do
          (1..run_count).each do
            pool.process { run_and_signal }
            cv.wait(mutex)
          end
        end
      end

      def run_and_signal
        mutex.synchronize do
          @threads_working += 1 if Thread.current != main_thread
          cv.signal
        end
        Thread.stop
      end

      it "wakes up a thread to process" do
        threads_working.should == run_count
      end

      it "removes a waiter" do
        pool.waiters.size.should == pool.threads.size - threads_working
      end

      it "returns the thread that is was selected to handle the task" do
        thread = pool.process { true }
        thread.is_a?(Thread)
        thread.should_not == Thread.current
      end

      describe "when the thread has finished processing" do
        it "returns a thread back to the waiting thread pool" do
          thread_count = pool.waiters.size
          thread_count.should == pool.threads.size - run_count
          thread = nil
          mutex.synchronize do
            thread = pool.process do
              mutex.synchronize do
                cv.signal
                cv.wait(mutex)
              end
            end
            cv.wait(mutex)
          end
          until thread.status == "sleep" do
            Thread.pass
          end
          pool.waiters.size.should == thread_count - 1
          cv.signal
          pool.waiters.size.should == thread_count
        end
      end
    end

    describe "when there are no threads waiting" do
      describe "when :block_on_exhaust is true" do
        attr_reader :mutex, :cv

        before do
          @pool = ThreadPool.new(thread_count, :block_on_exhaust => true)
          @mutex = Mutex.new
          @cv = ConditionVariable.new
          (1..thread_count-1).each do |i|
            pool.process { sleep 20 }
          end
        end

        after do
          pool.kill_all!
        end

        def signal_to_finish
          thread = nil
          mutex.synchronize do
            thread = pool.process do
              mutex.synchronize do
                cv.signal
                cv.wait(mutex)
              end
            end
            cv.wait(mutex)
          end

          until thread.status == "sleep" do
            Thread.pass
          end

          thread
        end

        it "waits for a thread to become available before processing" do
          signal_to_finish
          start_process_time = Time.now.to_f
          Thread.new do
            sleep 2
            cv.broadcast
          end
          pool.process { @process_called = true }
          (Time.now.to_f - start_process_time).should > 1.5  # Give 500ms leeway
        end
      end

      describe "when :block_on_exhaust is false" do
        it "spawns a new thread temporarily to handle the request"
      end

      describe "by default" do
        it "spawns a new thread temporarily to handle the request"
      end
    end

  end
end