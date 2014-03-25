set :stage, :staging

server 'dev.rbcitynews.ru',
  user: 'deploy',
  roles: %w{web app scheduler db},
  ssh_options: {
    port: 22
  }