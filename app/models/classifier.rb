class Classifier < ActiveRecord::Base
  attr_accessible :name

  has_many :classifier_text_class_feature_properties
  has_many :text_class_features, :through => :classifier_text_class_feature_properties  
end
