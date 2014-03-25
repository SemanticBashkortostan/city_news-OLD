namespace :unicorn do
  [:start, :stop, :restart].each do |action|
    desc "Unicorn: #{action}"
    task action do
      on roles(:app), in: :parallel, wait: 5 do
        sudo "/etc/init.d/unicorn #{action}"
      end
    end
  end

  task :setup do
    set_default :unicorn_pidfile, "#{fetch(:pids_path)}/unicorn.pid"
    set_default :unicorn_config, "#{current_path}/config/unicorn.rb"
    set_default :unicorn_concurrency, 2
    set_default :unicorn_socket, "3000"
    set_default :unicorn_user, "deploy"

    on roles(:all) do
      template "/unicorn/unicorn.rb.erb", "#{shared_path}/config/unicorn.rb"
      init_script "/unicorn/unicorn.init.erb", "unicorn"
    end
  end
end