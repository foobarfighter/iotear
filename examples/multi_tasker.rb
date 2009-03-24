#!/usr/bin/env ruby

# I like to run this script under "time"
# time ruby multi_tasker.rb
Thread.abort_on_exception = true

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
    # Runs faster in 1.8.7 than jruby and MRI 1.9.x when synchronizing.
    # This is due to overhead with context switching so many times with native threads.
    @mutex.synchronize do
      @counter += 1
    end
  end
end

def expensive_computation(counter, end_index)
  (1..end_index).each do |i|
    counter.inc
  end
end

pool = ThreadPool.new(thread_count, :block_on_exhaust => false)

runtime_tic = Time.now
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

puts "Total time: #{Time.now.to_f - runtime_tic.to_f} millis"
