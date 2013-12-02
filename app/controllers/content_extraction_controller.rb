class ContentExtractionController < ApplicationController
  before_filter :authenticate_user!


  def index
    @feed_sources = FeedSource.all      
  end


  def extract    
    @feed_sources = FeedSource.all 
    @feed_source = FeedSource.find params[:feed_source]
    @feed = @feed_source.feeds.order("RANDOM()").first

    @content = ContentExtractor.get(:pipeline, url: @feed.url)

    render action: 'index'
  end

end
