class TextClassFeature < ActiveRecord::Base
  belongs_to :text_class
  belongs_to :feature

  has_many :classifier_text_class_feature_properties
  has_many :classifiers, :through => :classifier_text_class_feature_properties


  def self.import_to_naive_bayes
    words_count = TextClassFeature.where(:text_class_id => TextClass.where( :name => Settings.bayes.klasses ) ).
                  where('feature_count IS NOT NULL')

    result_hash = { :docs_count => {}, :words_count => {}, :vocabolary => {} }
    words_count.each do |text_class_feature|
      result_hash[:words_count][text_class_feature.text_class_id] ||= {}
      result_hash[:words_count][text_class_feature.text_class_id][text_class_feature.feature.token] = text_class_feature.feature_count
    end

    result_hash[:docs_count] = Hash[ TextClass.all.collect{ |text_class| [ text_class.id, text_class.feeds.tagged_with(["dev_train", "was_trainer"], :any => true).count ] } ]
    result_hash[:vocabolary] = Set.new( words_count.uniq.pluck(:feature_id).map{|feature_id| Feature.find(feature_id).token } )
    return result_hash
  end
end