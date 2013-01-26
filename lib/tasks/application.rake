#coding: utf-8

namespace :application do
  desc "Fully destroy old application state and make reloading WITHOUT destroying existing data"
  task :reload_state => :environment do
    TextClassFeature.destroy_all
    Rake::Task['bayes:init_train'].invoke
  end
end