require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), 'spec_helper')

Spec::Runner.configure do |configuration|
  # Configure RSpec here
end

Dir[File.dirname(__FILE__) + "/**/*_spec.rb"].each do |file|
  require file
end

puts "Running on ruby " + VERSION + ", " + RUBY_PLATFORM
Spec::Runner.run