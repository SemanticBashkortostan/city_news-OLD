#set :domain, "151.248.116.233"
#set :worker_server, '37.140.195.245'
#
#role :web, domain                          # Your HTTP server, Apache/etc
#role :app, domain                          # This may be the same as your `Web` server
#role :db,  domain, :primary => true        # This is where Rails migrations will run
#role :worker, worker_server

# Whenever
#set :whenever_roles, :worker
#set :whenever_command, "bundle exec whenever"

set :stage, :production

server 'app.rbcitynews.ru',
  user: 'deploy',
  roles: %w{web app db},
  ssh_options: {
    port: 22
  }

server 'workers.rbcitynews.ru',
  user: 'deploy',
  roles: %w{scheduler},
  ssh_options: {
    port: 22
  }