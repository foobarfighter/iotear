require "#{File.dirname(__FILE__)}/../lib/iotear"
require "#{File.dirname(__FILE__)}/tools/test_client"

require 'rubygems'
require 'spec'

Thread.abort_on_exception = true

def poll_for_sleep(thread)
  until thread.status == "sleep" do
    Thread.pass
  end
end

Spec::Runner.configure do |config|
  config.mock_with :rr
end
