# Model for store docs count for classifier's text_classes
# Mainly using by Naive Bayes
class DocsCount < ActiveRecord::Base
  attr_accessible :classifier_id, :docs_count, :text_class_id

  belongs_to :classifier
  belongs_to :text_class
end
