require 'spec_helper'

describe Feed do
  context '#callbacks' do 
    it "should set correct published_at" do 
    	feed_correct = FactoryGirl.create :feed, :url => "dasdsa"
    	(feed_correct.published_at < 1.day.ago).should == true 

    	uncorrect_date = Time.now + 5.days
    	feed_uncorrect = FactoryGirl.create :feed, :published_at => uncorrect_date
    	feed_uncorrect.published_at.should_not == uncorrect_date
    	(feed_uncorrect.published_at < 30.seconds.ago && feed_uncorrect.published_at > 30.minutes.ago).should == true
    end

    it 'should correctly update descendants_count' do 
      feed_parent = FactoryGirl.create :feed
      feed_child = FactoryGirl.create :feed
      feed_child.parent = feed_parent
      feed_child.save! && feed_parent.reload

      feed_parent.descendants_count.should == 1
      feed_child.descendants_count.should == 0 

      feed_child.parent = nil
      feed_child.save! && feed_parent.reload
      feed_parent.descendants_count.should == 0
      feed_child.descendants_count.should == 0 
    end
  end
end
