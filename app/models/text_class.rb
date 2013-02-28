class TextClass < ActiveRecord::Base
  attr_accessible :name

  has_many :feeds

  has_many :text_class_features
  has_many :features, :through => :text_class_features
  has_many :feed_sources
end
