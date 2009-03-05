#!/usr/bin/env ruby

require 'thread'

main_mutex = Mutex.new
a_mutex = Mutex.new
b_mutex = Mutex.new

t1 = Thread.new do
  b_mutex.synchronize {
    sleep 0.01
    puts "t1: trying to get lock on a_mutex"
    a_mutex.synchronize {
      puts "never gonna get it"
    }
  }
end

t2 = Thread.new do
  a_mutex.synchronize {
    sleep 0.01
    puts "t2: trying to get lock on b_mutex"
    b_mutex.synchronize {
      puts "oh you're never gonna get it"
    }
  }
end

t1.join
t2.join

puts "Done"