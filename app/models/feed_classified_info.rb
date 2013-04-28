class FeedClassifiedInfo < ActiveRecord::Base
  attr_accessible :classifier_id, :feed_id, :score, :text_class_id, :to_train

  belongs_to :feed
  belongs_to :classifier
  belongs_to :text_class

  default_scope where('text_class_id is not NULL')
end
