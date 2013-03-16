require 'daemons'
require File.expand_path('../../config/boot',        __FILE__)
require File.expand_path('../../config/environment', __FILE__)


Daemons.run_proc("clock") do 
  Dir.chdir(Rails.root)
  system "bundle exec clockwork #{Rails.root}/lib/clock.rb"
end