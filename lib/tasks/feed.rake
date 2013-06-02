#coding: utf-8

namespace :production_feeds do

  task :fetch_outlier_feeds => :environment do
    Scheduler::ProductionFeedsFetcher.new.fetch_outlier_feeds
  end


  task :fetch_and_classify => :environment do
    Scheduler::ProductionFeedsFetcher.new.fetch_and_classify
  end

end

