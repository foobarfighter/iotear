require "#{File.dirname(__FILE__)}/spec_helper.rb"
require 'thread'

describe ThreadPool do
  attr_reader :thread_count, :pool, :thread_names

  def kill_threads(pool)
    pool.threads.each do |thread|
      thread.kill!
    end
  end

  before do
    @thread_count = 10
    @pool = ThreadPool.new(@thread_count)
    @thread_names = pool.threads.collect { |thread| thread[:name] }
    thread_names.size.should == thread_count
  end

  after do
    kill_threads(pool)
  end

  context "#initialize" do
    it "sets cv" do
      pool.cv.should_not be_nil
    end

    it "sets the threads" do
      pool.threads.should_not be_nil
      pool.threads.size.should == 10
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

  context "#process" do
    describe "when there are threads waiting" do
      attr_reader :one_thread_working
      
      it "wakes up a thread to process" do
        @threads_working = 0
        def sleepy
          sleep 1 # Should be enough time to see if all threads are working
        end
        pool.process { sleepy }
        
        pool.threads.each do |thread|
          @threads_working += 1 if thread[:status] == 'run'
        end
        @threads_working.should == 1
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