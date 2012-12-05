class TextClass < ActiveRecord::Base
  attr_accessible :name

  has_many :feeds
  has_and_belongs_to_many :features
end
