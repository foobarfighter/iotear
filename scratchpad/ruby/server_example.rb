#!/usr/bin/env ruby

$LOAD_PATH << "#{File.dirname(__FILE__)}/../../lib"

require 'iotear'
require File.dirname(__FILE__) + '/server'

def do_connect(client)
  puts "#{client.uuid.to_s} connected!"
end

def do_disconnect

end

def do_message

end


server = NonBlockServer.new(8888) do |s|
  s.on_connect { |client| do_connect(client) }
#  server.on_disconnect { do_disconnect }
#  server.on_message { do_message }
#  server.on_write_success { do_message }
#  server.on_write_fail { do_message }
#  server.on_error { do_error }
end

server.run
