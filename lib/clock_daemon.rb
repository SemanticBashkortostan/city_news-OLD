require 'daemons'

ENV["APP_ROOT"] ||= File.expand_path("#{File.dirname(__FILE__)}/..") 

Daemons.run_proc("clock_ruby") do
  Dir.chdir(ENV["APP_ROOT"])

  require "#{ENV["APP_ROOT"]}/lib/clock.rb"
  Clockwork::run  
end