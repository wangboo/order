#encoding: utf-8
require "mongoid"
require "yaml"
ENV["MONGOID_ENV"] = "development"
Mongoid.load!("./config/mongo.yml")
require "./mongo_addon.rb"
Dir.new("#{Dir.pwd}/models").each{|name|require "./models/#{name}" if name=~/^model_/}

require "active_support/time"

# puts User.all
puts Menu.all

