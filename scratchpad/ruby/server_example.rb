#!/usr/bin/env ruby

$LOAD_PATH << "#{File.dirname(__FILE__)}/../../lib"

require 'iotear'
require File.dirname(__FILE__) + '/server'

users = []

class User
  attr_reader :username, :client
  attr_writer :username

  def initialize(client)
    @username = nil
    @client = client
  end

  def logged_in?
    !@username.nil?
  end
end

class Chat

  def initialize
    @users = []
  end

  def add_user(user)
    @users << user
    prompt_login user
  end

  def prompt_login(user)
    user.client << "Please enter a username: "
  end

  def send_join(joiner)
    send_message(joiner, "has joined\n")
  end

  def send_message(sender, message)
    @users.each do |user|
      deliver_message(sender, user, message)
    end
  end

  def send_quit(quitter)
    send_message(quitter, "has quit\n") 
  end

  def deliver_message(from, to, message)
    to.client << "[#{from.username}] #{message}" if from != to && to.logged_in?
  end

  def find_user(client)
    @users.find { |user| user.client == client }
  end
end

server = NonBlockServer.new(8888) do |s|

  chat = Chat.new

  s.on_connect do |client|
    puts "#{client.uuid.to_s} connected"
    chat.add_user(User.new(client))
  end

  s.on_disconnect do |client|
    puts "#{client.uuid.to_s} disconnected"
    if quitter = chat.find_user(client)
      chat.send_quit(quitter)
    end
  end

  s.on_message do|client, message_block|
    puts "#{client.uuid.to_s} sent message: #{message_block.chomp}"
    if user = chat.find_user(client)
      if user.logged_in?
        chat.send_message(user, message_block)
      else
        user.username = message_block.chomp
        chat.send_join(user)
      end
    end
  end

  s.on_write_success do |client, message_block|
    puts "#{client.uuid} was delivered message: #{message_block}"
  end
end

server.run
