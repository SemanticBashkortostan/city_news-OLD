source 'https://rubygems.org'

ruby '2.0.0'

gem 'rails', '3.2.16'
gem 'pg'
gem 'activeadmin', '~> 0.6.3'

gem 'activerecord-postgres-hstore'

gem 'ancestry'

gem 'jquery-rails'

gem "haml", "~> 3.1.7"
gem "bootstrap-sass", "~> 2.3.2.0"
gem "devise", "~> 3.1.1"
gem "cancan", "~> 1.6.8"
gem "rolify", "~> 3.2.0"
gem "simple_form", "~> 2.0.4"
gem "kaminari"
gem "feedzirra", "~> 0.2.0.rc2"
gem "settingslogic"
gem "acts-as-taggable-on"
gem "simpleidn"
gem 'daemons'
gem 'clockwork', '~> 0.7.3'
gem 'russian'
gem 'replicate'

gem 'honeybadger', '~> 1.11.2'

gem 'rabl-rails'

gem 'sitemap_generator'

gem "naive_bayes", :git => "git://github.com/sld/naive_bayes.git", :ref => '3def7f1861dd7370fa10e6351216662a3b980117'

gem "feedbacks", :git => "git://github.com/sld/feedbacks.git"

gem 'ruby-stemmer', '~> 0.9.3', :require => 'lingua/stemmer'

gem 'state_machine'

gem 'activeresource'

gem 'rack-mini-profiler'

gem 'capistrano', '~> 3.1.0'
gem 'capistrano-rails', '~> 1.1'
gem 'unicorn'

group :production do
  gem 'dumper'
end

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  gem "therubyracer", ">= 0.10.2", :platform => :ruby
  gem 'turbo-sprockets-rails3'
end

group :development do
  gem "haml-rails", ">= 0.3.5"
  gem "hpricot", ">= 0.8.6"
  gem "ruby_parser", ">= 3.0.1"
  gem "quiet_assets", ">= 1.0.1"
  gem 'thin'
end

group :test do
  gem "database_cleaner", ">= 0.9.1"
  gem "email_spec", ">= 1.4.0"
  gem "launchy", ">= 2.1.2"
  gem "capybara", ">= 1.1.3"
  gem "cucumber-rails", ">= 1.3.0", :require => false
end

group :development, :test do
  gem "factory_girl_rails", ">= 4.1.0"
  gem "rspec-rails", ">= 2.11.4"
end