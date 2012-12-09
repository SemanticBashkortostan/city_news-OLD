#coding: utf-8
namespace :training_feeds do
  sources = { :ishimbay => ["http://ishimbay-news.ru/rss.xml"],
               :salavat => ["http://slvnews.ru/rss"],
               :ufa => ["http://rssportal.ru/feed/129727.xml", "http://news.yandex.ru/Ufa/index.rss"],
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


  # Получаем новости с нескольких источников для одного города
  # Количество делится поровну, например если нужно 50, то с каждого источника возьмется по 25
  def fetch_and_create_feed(paths, city, range=(0..50))
    to = range.first
    feed = Feedzirra::Feed.fetch_and_parse( paths )
    paths.each_with_index do |path, ind|
      from = to
      to = range.last/(paths.count - ind)
      rng = (from..to)
      feed[path].entries[rng].each do |entry|
        text_class = TextClass.find_by_name city
        create_feed( entry, text_class )
      end
    end
  end

  task :ishimbay => :environment do
    fetch_and_create_feed( sources[:ishimbay], "Ишимбай" )
  end


  task :salavat => :environment do
    fetch_and_create_feed( sources[:salavat], "Салават" )
  end


  task :ufa => :environment do
    fetch_and_create_feed( sources[:ufa], "Уфа" )
  end


  task :sterlitamak => :environment do
    fetch_and_create_feed( sources[:sterlitamak], "Стерлитамак" )
  end

end
