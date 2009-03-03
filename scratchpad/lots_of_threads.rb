#!/usr/bin/env ruby

require 'thread_factory'

THREAD_RUNTIME_SECONDS = 10
MAX_THREADS = 2

threads = []
(1..MAX_THREADS).each do
  #threads << ThreadFactory.create(:file_writer, :buffer_size => 1024, :run_until => run_until)
  threads << ThreadFactory.create(:computation, :run_seconds => THREAD_RUNTIME_SECONDS)
end

puts "Spawned #{threads.size} threads"

puts "Running all threads"
threads.each do |t|
  puts "Running #{t[:name]}..."
  t.run
end

# Wait on all threads to finish
puts "Waiting on all threads to finish"
threads.each do |t|
  t.join
end

# Threads finished, lets see what they did
ThreadFactory.computation_map.sort { |a, b| b[1] <=> a[1] }.each do |pair| 
  puts "#{pair[0]} counted to: #{pair[1]}"
end