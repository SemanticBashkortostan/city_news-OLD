namespace :monit do
  namespace :unicorn do
    [:start, :stop].each do |action|
      desc "#{action.capitalize} unicorn with monit"
      task action do
        on roles(:app) do
          sudo :monit, "#{action}", "unicorn"
        end
      end
    end

    task :restart do
      on roles(:app) do
        sudo :touch, "#{fetch(:pids_path)}/unicorn-restart.txt"
      end
    end
  end

  namespace :scheduler do
    [:start, :stop, :restart].each do |action|
      desc "#{action.capitalize} clockwork with monit"
      task action do
        on roles(:scheduler) do
          sudo :monit,"-g clockwork", "#{action}"
        end
      end
    end
  end


  desc "Place monit configs to where they belongs"
  task :setup do
    set_default :unicorn_restart_file, "#{fetch(:pids_path)}/unicorn-restart.txt"

    monitored_names = %w(unicorn clockwork)
    path_template = "/etc/monit/conf.d/:name:.monitrc"
    monitored_paths = monitored_names.map { |n| path_template.sub(":name:", n) }

    on roles(:all) do
      sudo :rm, "-f", monitored_paths.join(" ")
    end

    on roles(:app) do
      monit_config "/monit/unicorn.monitrc.erb", "unicorn.monitrc"
    end

    on roles(:scheduler) do
      monit_config "/monit/clockwork.monitrc.erb", "clockwork.monitrc"
    end

    on roles(:all) do
      sudo :monit, "reload"
    end
  end
end
