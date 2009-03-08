#!/usr/bin/env ruby

require 'optparse'
require 'thread_factory'

options = { :run_seconds => 5, :max_threads => 4 }
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} [options]"
  opts.on("-s", "--secconds [FLOAT]", "Thread runtime in seconds") do |v|
    options[:run_seconds] = v
  end
  opts.on("-c", "--count [FLOAT]", "Thread number of threads to spin up") do |v|
    options[:max_threads] = v.to_i
  end
end.parse!

MAX_THREADS = options[:max_threads]
THREAD_RUNTIME_SECONDS = options[:run_seconds]

puts "Creating #{MAX_THREADS} to run for #{THREAD_RUNTIME_SECONDS} seconds each"

# The main pool mutex and condition variables
mutex = Mutex.new
cv = ConditionVariable.new

threads = []
(1..MAX_THREADS).each do
  threads << ThreadFactory.create(:computation, mutex, cv, :run_seconds => THREAD_RUNTIME_SECONDS)
end

puts "Spawned #{threads.size} threads"
puts "Running threads:"
threads.each do |t|
  puts "About to run thread: #{t[:name]}..."
end

puts "Ready? Go!"
mutex.synchronize {
  cv.broadcast
  puts "Waiting on all threads to finish"
}

timeout = []
threads.each do |t|
  timeout << t.join
end
puts timeout.find(nil) ? "All threads exited successfully" : "At least one thread timed-out on join"

# Threads finished, lets see what they did
ThreadFactory.computation_map.sort { |a, b| b[1] <=> a[1] }.each do |pair|
  puts "#{pair[0]} counted to:\t#{pair[1]}"
end

counts = threads.collect { |t| ThreadFactory.computation_map[t[:name]] || 0 }.sort
median = counts.size % 2 == 0 ? (counts[counts.size/2] + counts[counts.size/2-1]).to_f/2.0 : counts[counts.size/2]
sum = counts.inject(0) { |acc, item| acc += item }
mean = sum.to_f/counts.size.to_f

puts ""
puts "Results:"
puts "========"
puts "Total:    #{sum}"
puts "Minimum:  #{counts.min}"
puts "Maximum:  #{counts.max}"
puts "Median:   #{median}"
puts "Mean:     #{mean}"