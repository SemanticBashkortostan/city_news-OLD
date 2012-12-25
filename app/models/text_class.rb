class TextClass < ActiveRecord::Base
  attr_accessible :name

  has_many :feeds
  has_many :classified_feeds, :class_name => 'Feed', :foreign_key => 'assigned_class_id'

  has_many :text_class_features
  has_many :features, :through => :text_class_features
end
