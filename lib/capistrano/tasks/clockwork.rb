namespace :clockwork do
  [:start, :stop, :restart].each do |action|
    desc "Clockwork: #{action}"
    task action do
      on roles(:scheduler), in: :parallel, wait: 5 do
        sudo "/etc/init.d/clockwork #{action}"
      end
    end
  end

  task :setup do
    set_default :clockwork_user, "deploy"
    set_default :clockwork_config, "#{current_path}/lib/clock.rb"
    set_default :clockwork_id, "clock_daemon"
    set_default :clockwork_pidfile, "#{fetch(:pids_path)}/clockworkd.#{fetch(:clockwork_id)}.pid"

    on roles(:all) do
      init_script "/clockwork/clockwork.init.erb", "clockwork"
    end
  end
end