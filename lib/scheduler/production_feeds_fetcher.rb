#
# CityNews - news aggregator software
# Copyright (C) 2013  Idris Yusupov
#
# This file is part of CityNews.
#
# CityNews is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# CityNews is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with CityNews.  If not, see <http://www.gnu.org/licenses/>.
#
class Scheduler::ProductionFeedsFetcher


  def create_production_feed entry, options = {}, only_new=false
    params = {
               :title => entry.title[0...255], :url => entry.url, :summary => entry.summary,
               :published_at => Time.local( entry.published.year, entry.published.month, entry.published.day, entry.published.hour, entry.published.min ),
               :mark_list => ["fetched", "production"]
             }.merge( options )
    only_new ? Feed.new( params ) : Feed.create( params )
  end


  def make_tmp_feeds entries
    entries.collect{|entry| create_production_feed(entry, {}, true) }
  end


  def get_outlier_and_goods(feeds)
    onb = OutlierNb.new
    onb.preload
    onb.classify feeds
  end


  def fetch_outlier_feeds
    paths = ["http://news.yandex.ru/world.rss", "http://news.yandex.ru/health.rss", "http://news.yandex.ru/science.rss",
            "http://news.yandex.ru/business.rss", "http://news.yandex.ru/computers.rss",  "http://news.yandex.ru/culture.rss"]            
    feed = Feedzirra::Feed.fetch_and_parse( paths )
    paths.each do |path| 
      begin
        tmp_feeds = make_tmp_feeds( feed[path].entries )
        outliers = get_outlier_and_goods( tmp_feeds )[:outlier]
        outliers.each do |feed|
          feed.mark_list = ["outlier"]
          feed.save!
        end
      rescue Exception => e 
        p ["Error in production_feeds:fetch_outlier_feeds #{path}", e]
        Honeybadger.notify e
      end    
    end
  end


  def fetch
    max_fetched = 20
    paths = FeedSource.active.pluck(:url)
    feed = Feedzirra::Feed.fetch_and_parse( paths )
    paths.each do |path|
      begin
        fetched = 0
        tmp_feeds = make_tmp_feeds( feed[path].entries )
        outlier_and_goods = get_outlier_and_goods( tmp_feeds )
        outlier_and_goods[:good].each do |feed|
          @feed_url = feed.url  # To resolve issue in Honeybadger
          fetched += 1 if feed.save           
          break if fetched >= max_fetched
        end
        outlier_and_goods[:outlier].each do |feed|
          feed.mark_list = ["new_unsatisfaction"]
          feed.save
        end
      rescue Exception => e
        str = ["Error in production_feeds:fetch_and_classify #{path}", e]
        p str
        BayesLogger.bayes_logger.error str
        Honeybadger.context(feed_source_path: path, feed_url: @feed_url)
        Honeybadger.notify e
        raise Exception if Rails.env == "development"
      end
    end
  end


  def classify
    Scheduler::Classifier.classify_fetched
  end


  def fetch_and_classify
    VocabularyEntry.testing_mode = 1
    fetch
    classify
    VocabularyEntry.testing_mode = nil
  end

end