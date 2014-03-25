namespace :support do
  namespace :db do
    desc 'Runs rake db:create'
    task :create do
      on primary fetch(:migration_role) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            execute :rake, "db:create"
          end
        end
      end
    end
  end

  desc "Loads rails console on production"
  task :console => ["deploy:set_rails_env"] do
    execute_interactively "rails console"
  end

  def execute_interactively(command, role = :support)
    sequence = <<STR
    cd #{current_path}; RAILS_ENV=#{fetch(:rails_env)} bundle exec #{command}
STR
    host, port, user = connection_params role

    exec "ssh -t #{user}@#{host} -p#{port} '#{sequence}'"
  end

  def connection_params(role)
    server = roles(role).first
    host = server.hostname
    user = server.ssh_options[:user] || server.user
    port = server.ssh_options[:port] || server.port

    [host, port, user]
  end
end
