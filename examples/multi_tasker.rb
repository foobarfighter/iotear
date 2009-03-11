#!/usr/bin/env ruby
$LOAD_PATH << "../lib"
require 'iotear'

thread_count = 10

# yeah... so it's not *that* expensive ;)
def expensive_computation(index)
  index += index * index
end

pool = ThreadPool.new(thread_count)

(1..thread_count).each do |i|
  pool.process { expensive_computation i }
  sleep 1
end