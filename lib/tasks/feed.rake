#coding: utf-8
namespace :training_feeds do
  sources = { :ishimbay => "http://ishimbay-news.ru/rss.xml",
               :salavat => "http://slvnews.ru/rss",
               :ufa => "http://rssportal.ru/feed/129727.xml",
               :sterlitamak => ["http://rssportal.ru/feed/223350.xml"]}
  # http://rssportal.ru/


  def create_feed entry, text_class, options={}
    params = {:title => entry.title, :url => entry.url, :summary => entry.summary, :published_at => entry.published,
                     :text_class => text_class, :mark_id => Feed::TRAINING}.merge( options )
    Feed.create params
  end


  #TODO: Подчистить код, т.к для быстрого получения девелопмент даты пришлось испачкаться
  def satisfaction?(city, entry)
    regexp = nil
    case city
      when "Уфа" then regexp = /(Уф+[[:word:]]+|УФ+[[:word:]]+|уфи+[[:word:]]+)/
      when "Стерлитамак" then regexp = /(Стерл+[[:word:]]+|СТЕРЛ+[[:word:]]+|стерл+[[:word:]]+)/
    end
    return true unless entry.title.scan(regexp).empty?
    return true unless entry.summary.scan(regexp).empty?
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
    feed.entries[80..130].each do |entry|
      text_class = TextClass.find_by_name "Салават"
      create_feed( entry, text_class )
    end
  end


  task :ufa => :environment do
    feed = Feedzirra::Feed.fetch_and_parse( sources[:ufa] )
    feed.entries[16..20].each do |entry|
      text_class = TextClass.find_by_name "Уфа"
      
      create_feed( entry, text_class, :mark_id => Feed::DEV_TEST ) if satisfaction?( "Уфа", entry )
    end
  end


  task :sterlitamak => :environment do
    feed = Feedzirra::Feed.fetch_and_parse( sources[:sterlitamak] )
    feed[ sources[:sterlitamak][0] ].entries[111..130].each do |entry|
      text_class = TextClass.find_by_name "Стерлитамак"

      create_feed( entry, text_class, :mark_id => Feed::DEV_TEST ) if satisfaction?( "Стерлитамак", entry )
    end
  end

end
