#coding: utf-8

rss_sources = { :ishimbay => ["http://ishimbay-news.ru/rss.xml", "http://ishimbai.procrb.ru/rss/?rss=y",
                          "http://vestivmeste.ru/index.php/v-dvuh-slovah?format=feed&type=rss",
                          "http://восход-ишимбай.рф/index.php?option=com_content&view=category&id=8&Itemid=598&format=feed&type=rss",
                          "http://восход-ишимбай.рф/index.php?option=com_content&view=category&id=10&Itemid=600&format=feed&type=rss",
                          "http://восход-ишимбай.рф/index.php?option=com_content&view=category&id=26&Itemid=601&format=feed&type=rss",
                          "http://восход-ишимбай.рф/index.php?option=com_content&view=category&id=12&Itemid=602&format=feed&type=rss"
                          ],
             :salavat => ["http://slvnews.ru/rss", "http://rssportal.ru/feed/163654.xml" ],
             :ufa => ["http://rssportal.ru/feed/129727.xml", "http://news.yandex.ru/Ufa/index.rss"],
             :sterlitamak => ["http://rssportal.ru/feed/223350.xml", "http://sterlegrad.ru/rss.xml", "http://cityopen.ru/?feed=rss2"],
             :neftekamsk => ["http://neftekamsk.procrb.ru/rss/?rss=y", "http://rssportal.ru/feed/240378.xml",
                             "http://feeds.feedburner.com/delogazeta/UGfI?format=xml"],
             :other => ["http://feeds.feedburner.com/bashinform/all?format=xml"]}
count80 = 56
count20 = 14

namespace :training_feeds do

  sql_sources = {:ishimbay => "select nid, created, title, text from rb7_news where title like '%Ишимб%' order by title desc",
                  :neftekamsk => "select nid, created, title, text from rb7_news where title like '%Нефтек%' order by title desc"}


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
  def fetch_and_create_feed(paths, city, max = 48)
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
          throw :done if fetched >= max
        end
      end
    end
  end


  def fetch_and_create_feed_by_sql query, city, max = 12, tag="dev_test"
    fetched = 0
    feeds = ActiveRecord::Base.connection.execute query
    catch(:done) do
      feeds.each do |row|
        fetched += 1
        text_class = TextClass.find_by_name city
        params = {:title => row["title"], :url => "http://www.rb7.ru/node/#{row['nid']}", :summary => row["text"],
                  :published_at => Time.at(row["created"].to_i), :text_class => text_class, :mark_list => [tag] }
        Feed.create params
        throw :done if fetched >= max
      end
    end
  end


  desc "Setting dev test and dev train tags for fetched feeds"
  task :set_dev_test_and_train_feeds => :environment do
    fetched = 0
    TextClass.all.each do |text_class|
      feeds = Feed.where( :text_class_id =>  text_class.id ).tagged_with(["classified", "production"]).order("RANDOM()").all
      while fetched <= count80 && feeds.count > fetched do
        feed = feeds[fetched]
        if satisfaction?( feed, feed.text_class.name )
          feed.text_class = text_class
          feed.mark_list = ["dev_train"]
          feed.save!
          fetched += 1
        end
      end
      while fetched <= (count80 + count20) && feeds.count > fetched
        feed = feeds[fetched]
        if satisfaction?( feed, feed.text_class.name )
          feed.text_class = text_class
          feed.mark_list = ["dev_test"]
          feed.save!
        end
      end
    end
  end


  desc "Checking dev test and dev train feeds by cities regexp"
  task :check_devs_by_regexp => :environment do
    p ["dev_test_count is not true"] if Feed.tagged_with("dev_test").count != count20 * TextClass.count
    p ["dev_train_count is not true"] if Feed.tagged_with("dev_train").count != count80 * TextClass.count
    Feed.tagged_with(["dev_test", "dev_train"], :any => true).all.each do |feed|
      if not satisfaction?( feed.text_class.name, feed )
        p ["is not satisfaction", feed]
      end
    end
  end


  task :ishimbay => :environment do
    #fetch_and_create_feed( rss_sources[:ishimbay], "Ишимбай" )
    fetch_and_create_feed_by_sql( sql_sources[:ishimbay], "Ишимбай", 9 )
  end


  task :neftekamsk => :environment do
    #fetch_and_create_feed( rss_sources[:neftekamsk], "Нефтекамск" )
    fetch_and_create_feed_by_sql( sql_sources[:neftekamsk], "Нефтекамск", 4 )
  end


  task :salavat => :environment do
    fetch_and_create_feed( rss_sources[:salavat], "Салават" )
  end


  task :ufa => :environment do
    fetch_and_create_feed( rss_sources[:ufa], "Уфа" )
  end


  task :sterlitamak => :environment do
    fetch_and_create_feed( rss_sources[:sterlitamak], "Стерлитамак" )
  end

end


namespace :production_feeds do
  def create_production_feed entry, options = {}
    params = {
               :title => entry.title, :url => entry.url, :summary => entry.summary,
               :published_at => Time.local( entry.published.year, entry.published.month, entry.published.day, entry.published.hour, entry.published.min ),
               :mark_list => ["fetched", "production"]
             }.merge( options )
    Feed.create params
  end


  def production_satisfaction?(entry)
    regexp = Regexp.new Settings.bayes.regexp.values.collect{|e| e[0]}.join("|")
    str = entry.title + " " + entry.summary
    not str.scan(regexp).empty?
  end


  task :fetch_and_classify => :environment do
    max_fetched = 15
    fetched = 0
    paths = rss_sources.values.flatten
    feed = Feedzirra::Feed.fetch_and_parse( paths )
    paths.each do |path|
      feed[path].entries.each do |entry|
        create_production_feed( entry ) if production_satisfaction?( entry )
        fetched += 1
        break if fetched >= max_fetched
      end
      fetched = 0
    end
    Rake::Task['bayes:classify_fetched'].invoke
  end
end

