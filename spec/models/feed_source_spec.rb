require 'spec_helper'

describe FeedSource do
  describe "#available?" do
    before do 
      @available_feed_source = FactoryGirl.create :feed_source, :url => "http://feeds.feedburner.com/bashinform/all?format=xml"
      @unavailable_feed_source = FactoryGirl.create :feed_source, :url => "http://rssportal.ru/feed/240378.xml"
    end

    it "should return true for available feed source" do 
      @available_feed_source.available?.should be_true
    end

    it "should return false for unavailable feed source" do
      @unavailable_feed_source.available?.should be_false
    end
  end
end
