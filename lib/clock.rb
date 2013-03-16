require 'clockwork'

require File.expand_path('../../config/boot',        __FILE__)
require File.expand_path('../../config/environment', __FILE__)
require "#{Rails.root}/lib/scheduler/classifier"
require "#{Rails.root}/lib/scheduler/production_feeds_fetcher"

include Clockwork


every(3.minutes, 'production_feeds:fetch_and_classify') do
  Scheduler::ProductionFeedsFetcher.new.fetch_and_classify
end

every(11.minutes, 'fetch_other_feeds') do
   feeds_fetcher = Scheduler::ProductionFeedsFetcher.new
   feeds_fetcher.fetch_outlier_feeds
   feeds_fetcher.fetch_unsatisfaction_feeds
end

every(31.minutes, 'classifier:train_by_production_data') do
  Scheduler::Classifier.train_by_production_data
end

#TODO: Add Sitemap generation

