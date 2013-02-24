class FeedSource < ActiveRecord::Base
  attr_accessible :text_class_id, :url

  belongs_to :text_class

  validates :url, :uniqueness => true
end
