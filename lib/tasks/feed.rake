#coding: utf-8
namespace :feed do
  sources = { :ishimbay => "http://ishimbay-news.ru/rss.xml",
               :salavat => "http://slvnews.ru/rss",
               :ufa =>  "http://news.yandex.ru/Ufa/index.rss" }


  def create_feed entry, text_class
    Feed.create! :title => entry.title, :url => entry.url, :summary => entry.summary, :published_at => entry.published, :text_class => text_class
  end


  task :ishimbay => :environment do
    feed = Feedzirra::Feed.fetch_and_parse( sources[:ishimbay] )
    feed.entries[0..50].each do |entry|
      text_class = TextClass.find_by_name "Ишимбай"
      create_feed( entry, text_class )
    end
  end


  task :salavat => :environment do
    feed = Feedzirra::Feed.fetch_and_parse( sources[:salavat] )
    feed.entries[0..50].each do |entry|
      text_class = TextClass.find_by_name "Салават"
      create_feed( entry, text_class )
    end
  end


  task :ufa => :environment do
    feed = Feedzirra::Feed.fetch_and_parse( sources[:ufa] )
    feed.entries[0..50].each do |entry|
      text_class = TextClass.find_by_name "Уфа"
      create_feed( entry, text_class )
    end
  end

end
