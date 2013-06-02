class TextClassFeature < ActiveRecord::Base
  belongs_to :text_class
  belongs_to :feature

  has_many :classifier_text_class_feature_properties
  has_many :classifiers, :through => :classifier_text_class_feature_properties
end