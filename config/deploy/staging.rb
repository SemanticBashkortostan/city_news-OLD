set :stage, :staging

server 'dev.rbcitynews.ru',
  user: 'deploy',
  roles: %w{web app db},
  ssh_options: {
    port: 22
  }