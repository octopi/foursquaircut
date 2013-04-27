require 'rubygems'
require 'bundler'

Bundler.require
$stdout.sync = true
require './app.rb'
run Sinatra::Application