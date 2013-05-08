class Scheduler::ProductionFeedsFetcher


  def create_production_feed entry, options = {}, only_new=false
    params = {
               :title => entry.title, :url => entry.url, :summary => entry.summary,
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
      end    
    end
  end


  def fetch
    max_fetched = 20
    paths = FeedSource.pluck(:url)
    feed = Feedzirra::Feed.fetch_and_parse( paths )
    paths.each do |path|
      begin
        fetched = 0
        tmp_feeds = make_tmp_feeds( feed[path].entries )
        outlier_and_goods = get_outlier_and_goods( tmp_feeds )
        outlier_and_goods[:good].each do |feed|
          feed.save!
          fetched += 1
          break if fetched >= max_fetched
        end
        outlier_and_goods[:outlier].each do |feed|
          feed.mark_list = ["new_unsatisfaction"]
          feed.save!
        end
      rescue Exception => e
        str = ["Error in production_feeds:fetch_and_classify #{path}", e]
        p str
        BayesLogger.bayes_logger.error str
        raise Exception
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
  end

end