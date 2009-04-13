#!/usr/bin/env ruby

$LOAD_PATH << "#{File.dirname(__FILE__)}/../../lib"

require 'iotear'
require File.dirname(__FILE__) + '/server'

Server.new(8888)
