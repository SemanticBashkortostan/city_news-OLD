class ClassifierTextClassFeatureProperty < ActiveRecord::Base
  attr_accessible :classifier_id, :feature_count, :text_class_feature_id

  belongs_to :classifier
  belongs_to :text_class_feature
end
