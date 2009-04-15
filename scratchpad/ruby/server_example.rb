#!/usr/bin/env ruby

$LOAD_PATH << "#{File.dirname(__FILE__)}/../../lib"

require 'iotear'
require File.dirname(__FILE__) + '/server'

server = NonBlockServer.new(8888)

# TODO: Catch an interupt instead of while true
i = 0
while true
  server.try_accept
  server.try_reads
  server.try_writes
  sleep 0.001
  if i % 1000 == 0 && server.clients.size > 0
    srand(Time.now.to_i)
    write_client_index = server.clients.size > 1 ? rand(server.clients.size) : 0
    client = server.clients[write_client_index]
    client << "hello world, this is your non-blocking IO server speaking\n"
  end
  i += 1
end
