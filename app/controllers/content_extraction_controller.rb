class ContentExtractionController < ApplicationController
  before_filter :authenticate_user!


  def index
    @feed_sources = FeedSource.all
    @feed_source = FeedSource.find_by_id params[:feed_source]
  end


  def extract    
    @feed_sources = FeedSource.all 
    @feed_source = FeedSource.find params[:feed_source]
    @feed = @feed_source.feeds.order("RANDOM()").first

    @content = ContentExtractor.get(:pipeline, url: @feed.url)

    render action: 'index'
  end


  def extractable_feed_source
    @feed_source = FeedSource.find params[:feed_source]
    @feed_source.extractable_main_content = true
    @feed_source.save!
    redirect_to action: 'index', feed_source: params[:feed_source]
  end

end
