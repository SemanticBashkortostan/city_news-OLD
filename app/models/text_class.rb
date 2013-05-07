class TextClass < ActiveRecord::Base
  attr_accessible :name

  has_many :feeds

  has_many :text_class_features
  has_many :features, :through => :text_class_features
  has_many :feed_sources

  has_many :docs_counts
  has_many :classifiers, :through => :docs_counts

  has_and_belongs_to_many :vocabulary_entries
end
