#!/usr/bin/env ruby

require 'thread'

main_mutex = Mutex.new
a_mutex = Mutex.new
b_mutex = Mutex.new

a_cv = ConditionVariable.new
b_cv = ConditionVariable.new

# The execution order of t1 and t2 does not matter, they will always create a deadlock

t1 = Thread.new do
  b_mutex.synchronize {
    puts "t1: in b"
    puts "t1: trying to get a"
    a_mutex.synchronize {
      puts "t1: waiting on a"
      a_cv.wait(a_mutex)
      puts "t1: done waiting on a"
    }
  }
  puts "t1: out of b"
end

t2 = Thread.new do
  a_mutex.synchronize {
    puts "t2: in a"
    puts "t2: trying to get b"
    b_mutex.synchronize {
      puts "t2: waiting on b"
      b_cv.wait(b_mutex)
      puts "t2: done waiting on b"
    }
  }
  puts "t2: out of b"
end

# Sleep here to demonstrate that the lock can't be broken
# even if the main process waits for a while
sleep 2

t1.join
t2.join

puts "Done"