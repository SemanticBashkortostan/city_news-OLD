#coding: utf-8

# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :cron_log, "log/cron.log"

#NOTE: Development!
set :job_template, "bash -l -c -i 'source /home/mineralka/.rvm/environments/ruby-1.9.3-p374 && :job' "
set :environment, 'production'

every 3.minutes do
  rake "production_feeds:fetch_and_classify"
end

every 1.hour do
  rake "bayes:train_by_production_data"
end
