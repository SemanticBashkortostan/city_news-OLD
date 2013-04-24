class Scheduler::ProductionFeedsFetcher


  def create_production_feed entry, options = {}    
    params = {
               :title => entry.title, :url => entry.url, :summary => entry.summary,
               :published_at => Time.local( entry.published.year, entry.published.month, entry.published.day, entry.published.hour, entry.published.min ),
               :mark_list => ["fetched", "production"]
             }.merge( options )
    params[:new] ? Feed.new( params ) : Feed.create( params )
  end


  def make_tmp_feeds entries
    entries.collect{|entry| create_production_feed(entry, :new => true) }
  end


  #NOTE: Bad feelings take me when I look at this function!
  def production_satisfaction?(entry)
    regexp = Regexp.new Settings.bayes.regexp.values.join("|")
    str = entry.title + " " + entry.summary
    not str.scan(regexp).empty?

    @outlier_and_goods[:good].include?(entry)
  end


  def fetch_outlier_feeds
    paths = ["http://news.yandex.ru/world.rss", "http://news.yandex.ru/health.rss", "http://news.yandex.ru/science.rss",
            "http://news.yandex.ru/business.rss", "http://news.yandex.ru/computers.rss",  "http://news.yandex.ru/culture.rss"]            
    feed = Feedzirra::Feed.fetch_and_parse( paths )
    paths.each do |path| 
      begin      
        feed[path].entries.each do |entry|
          if not production_satisfaction?( entry ) 
            create_production_feed(entry, {:mark_list => ["outlier"]})
          end
        end
      rescue Exception => e 
        p ["Error in production_feeds:fetch_outlier_feeds #{path}", e]
      end    
    end
  end


  def fetch_unsatisfaction_feeds
    max_fetched = 50
    paths = FeedSource.pluck(:url)
    feed = Feedzirra::Feed.fetch_and_parse( paths )
    paths.each do |path|  
      fetched = 0  
      begin       
        feed[path].entries.each do |entry|
          if not production_satisfaction?( entry )
            create_production_feed( entry, {:mark_list => ["unsatisfaction"]} ) 
            fetched += 1
          end
          break if fetched >= max_fetched  
        end
      rescue Exception => e 
        p ["Error in production_feeds:fetch_unsatisfaction_feeds #{path}", e]
      end       
    end
  end


  def fetch_and_classify
    max_fetched = 15
    fetched = 0
    paths = FeedSource.pluck(:url)
    feed = Feedzirra::Feed.fetch_and_parse( paths )
    paths.each do |path|      
      begin
        tmp_feeds = make_tmp_feeds( feed[path].entries )
        #TODO: --- look down
        # Создаем массив @outlier_and_goods
        # Оттуда уже проверяем production_satisfaction
        # Кстати, если будешь идти по tmp_feeds, надо не create_production_enty делать, а сразу .create!
        feed[path].entries.each do |entry|
          if production_satisfaction?( entry )
            create_production_feed( entry ) 
            fetched += 1
          end
          break if fetched >= max_fetched       
        end        
      rescue Exception => e
        BayesLogger.bayes_logger.error ["Error in production_feeds:fetch_and_classify #{path}", e]
      end
      fetched = 0
    end
    Scheduler::Classifier.classify_fetched
  end

end