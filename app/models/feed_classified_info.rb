class FeedClassifiedInfo < ActiveRecord::Base
  attr_accessible :classifier_id, :feed_id, :score, :text_class_id, :to_train

  belongs_to :feed
  belongs_to :classifier
end
