require "#{File.dirname(__FILE__)}/spec_helper.rb"
require 'thread'

describe ThreadPool do
  attr_reader :thread_count, :pool

  before do
    @thread_count = 10
    @pool = ThreadPool.new(@thread_count)
  end

  context "#initialize" do
    it "creates n number of sleeping threads" do
      pool.threads.find_all { |thread| thread.status == "sleep" }.size.should == thread_count
    end

    describe "when a thread prefix is passed" do
      it "gives each thread a default name" do
        @pool = ThreadPool.new(@thread_count, :thread_prefix => "foo")
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
      it "wakes up a thread to process" do

        @threads_working = false
        def test_thread_status
          pool.threads.each do |thread|
            puts thread.status
            puts thread[:name]
          end
        end
        pool.process { test_thread_status }
        one_thread_working.should be_true
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