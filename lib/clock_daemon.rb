require 'daemons'
require File.expand_path('../../config/boot',        __FILE__)
require File.expand_path('../../config/environment', __FILE__)


Daemons.run_proc("clock") do 
  Dir.chdir(Rails.root)
  
  require "#{Rails.root}/lib/clock.rb"
  Clockwork::run  
end