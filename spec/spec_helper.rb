require "#{File.dirname(__FILE__)}/../lib/iotear"

require 'rubygems'
require 'spec'

def poll_for_sleep(thread)
  until thread.status == "sleep" do
    Thread.pass
  end
end