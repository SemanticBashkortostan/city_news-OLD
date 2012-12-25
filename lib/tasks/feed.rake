#coding: utf-8
namespace :training_feeds do
  sources = { :ishimbay => ["http://ishimbay-news.ru/rss.xml", "http://ishimbai.procrb.ru/rss/?rss=y",
                            "http://vestivmeste.ru/index.php/v-dvuh-slovah?format=feed&type=rss",
                            "http://восход-ишимбай.рф/index.php?option=com_content&view=category&id=8&Itemid=598&format=feed&type=rss",
                            "http://восход-ишимбай.рф/index.php?option=com_content&view=category&id=10&Itemid=600&format=feed&type=rss",
                            "http://восход-ишимбай.рф/index.php?option=com_content&view=category&id=26&Itemid=601&format=feed&type=rss"
                            ],
               :salavat => ["http://slvnews.ru/rss", "http://rssportal.ru/feed/163654.xml" ],
               :ufa => ["http://rssportal.ru/feed/129727.xml", "http://news.yandex.ru/Ufa/index.rss"],
               :sterlitamak => ["http://rssportal.ru/feed/223350.xml", "http://sterlegrad.ru/rss.xml"],
               :neftekamsk => ["http://neftekamsk.procrb.ru/rss/?rss=y", "http://rssportal.ru/feed/240378.xml"]}


  def create_feed entry, text_class, options={}
    params = {:title => entry.title, :url => entry.url, :summary => entry.summary, :published_at => entry.published,
                     :text_class => text_class, :mark_list => ["train"]}.merge( options )
    Feed.create params
  end


  def satisfaction?(city, entry)
    regexp = nil
    cities_regexp = Hash[ Settings.bayes.regexp.values.map{|e| e.reverse}]
    regexp = Regexp.new cities_regexp[city]
    str = entry.title + " " + entry.summary
    return true unless str.scan(regexp).empty?
  end


  # Получаем новости с нескольких источников для одного города
  # Новости начинает выбираться со следующего источника, пока не наберется указанное количество
  def fetch_and_create_feed(paths, city, max = 50)
    feed = Feedzirra::Feed.fetch_and_parse( paths )
    fetched = 0
    catch (:done) do
      paths.each_with_index do |path, ind|
        feed[path].entries.each do |entry|
          text_class = TextClass.find_by_name city
          if satisfaction? city, entry
            fetched += 1
            create_feed( entry, text_class )
          end
          throw :done if fetched >= 50
        end
      end
    end
  end


  task :ishimbay => :environment do
    fetch_and_create_feed( sources[:ishimbay], "Ишимбай" )
  end


  task :neftekamsk => :environment do
    fetch_and_create_feed( sources[:neftekamsk], "Нефтекамск" )
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

