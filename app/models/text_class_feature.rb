class TextClassFeature < ActiveRecord::Base
  belongs_to :text_class
  belongs_to :feature


  def self.import_to_naive_bayes
    words_count = select( 'text_class_id, feature_id, feature_count' ).
                  where(:text_class_id => TextClass.where( :name => Settings.bayes.klasses ) ).
                  where('feature_count IS NOT NULL')

    result_hash = { :docs_count => {}, :words_count => {}, :vocabolary => {} }
    words_count.each do |text_class_feature|
      result_hash[:words_count][text_class_feature.text_class_id] ||= {}
      result_hash[:words_count][text_class_feature.text_class_id][Feature.find(text_class_feature.feature_id).token] = text_class_feature.feature_count
    end

    result_hash[:docs_count] = Hash[ words_count.collect{ |text_class_feature| [text_class_feature.text_class_id, text_class_feature.feature_count] } ]
    result_hash[:vocabolary] = Set.new( words_count.uniq.pluck(:feature_id).collect{|e| Feature.find_by_token(e).token } )
    return result_hash
  end
end