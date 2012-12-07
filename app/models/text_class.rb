class TextClass < ActiveRecord::Base
  attr_accessible :name

  has_many :feeds
  has_many :classified_feeds, :class_name => 'Feed', :foreign_key => 'assigned_class_id'
  has_and_belongs_to_many :features
end
