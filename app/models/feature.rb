class Feature < ActiveRecord::Base
  attr_accessible :token

  has_many :text_class_features
  has_many :text_classes, :through => :text_class_features
end
