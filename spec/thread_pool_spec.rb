require "#{File.dirname(__FILE__)}/spec_helper.rb"
require 'thread'

describe ThreadPool do
  attr_reader :thread_count, :pool, :thread_names

  def kill_threads(pool)
    return if pool.threads.nil?

    pool.threads.each do |thread|
      thread.kill!
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
      @outside_thread.kill!
    end

    it "kills all threads that belong to the thread pool" do
      threads = pool.threads.dup
      pool.kill_all!
      threads.each { |thread| thread.status.should be_false }
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

  context "#process" do
    describe "when there are threads waiting" do
      attr_reader :mutex, :cv, :main_thread

      before do
        @mutex = Mutex.new
        @cv = ConditionVariable.new
        @main_thread = Thread.current
      end

      it "wakes up a thread to process" do
        @threads_working = 0
        def run_and_signal
          mutex.synchronize do
            @threads_working += 1 if Thread.current != main_thread
            cv.signal
          end
        end

        mutex.synchronize do
          pool.process { run_and_signal }
          cv.wait(mutex)
          pool.process { run_and_signal }
          cv.wait(mutex)
        end

        @threads_working.should == 2
      end
    end

    describe "when there are no threads waiting" do
      describe "when :block_on_exhaust is true" do
        it "waits for a thread to become available before processing"
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