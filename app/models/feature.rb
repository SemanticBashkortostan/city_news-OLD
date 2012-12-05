class Feature < ActiveRecord::Base
  attr_accessible :token

  has_and_belongs_to_many :text_classes
end
