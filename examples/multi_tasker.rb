#!/usr/bin/env ruby

# I like to run this script under "time"
# time ruby multi_tasker.rb

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"

require 'iotear'
Thread.abort_on_exception = true

thread_count = 10
end_index = 1000000

class Counter
  def initialize
    @counter = 0
    @mutex = Mutex.new
  end

  def value
    @counter
  end

  def inc
    # Ruby 1.9 doesn't race, but ruby 1.8.7 does when not synchronizing.
    # I think this is because 1.9 uses a global interpreter lock for multithreading
    # although I still don't understand what that means completely.
    #@mutex.synchronize do
      @counter += 1
    #end
  end
end

def expensive_computation(counter, end_index)
  (1..end_index).each do |i|
    counter.inc
  end
end

pool = ThreadPool.new(thread_count)

counter =  Counter.new
(1..thread_count).each do |i|
  pool.process { expensive_computation(counter, end_index) }
end

pool.join_all

expected_counter = thread_count * end_index
if counter.value == expected_counter
  puts "We didn't race! got expected: #{expected_counter}"
else
  puts "We raced, got: #{counter.value}, expected: #{expected_counter}"
end
