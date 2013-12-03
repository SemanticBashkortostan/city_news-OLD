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

set :job_template, "bash -l -i -c ':job'"
job_type :custom_ruby_exec, "cd :path && RAILS_ENV=:environment bundle exec ruby :task"
every :day do
  custom_ruby_exec "lib/clock_daemon.rb restart"
  custom_ruby_exec "lib/clock_daemon_similar.rb restart"
  custom_ruby_exec "lib/clock_daemon_main_content.rb restart"
end

# Learn more: http://github.com/javan/whenever
