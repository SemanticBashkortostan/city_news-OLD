#coding: utf-8

module ClassifierNaiveBayes

  def export_nb
    @classifier.export
  end


  def import_naive_bayes_data options={}
    ClassifierTextClassFeatureProperty.import_to_naive_bayes( self.id ).merge(form_docs_counts_hash).merge(options)
  end


  def preload_naive_bayes options
    @classifier = NaiveBayes::NaiveBayes.new
    nb_data = import_naive_bayes_data(options)
    @classifier.import!( nb_data[:docs_count], nb_data[:words_count], nb_data[:vocabolary]  )
  end


  def save_naive_bayes
    klass_words_count = @classifier.export[:words_count]
    klass_words_count.each do |klass_id, words_count|
      words_count.each do |word, cnt|
        begin
          tcf =  TextClassFeature.find_or_create_by_text_class_id_and_feature_id( klass_id, Feature.find_or_create_by_token( word ).id )
          ctcfp = ClassifierTextClassFeatureProperty.find_or_create_by_classifier_id_and_text_class_feature_id( self.id, tcf.id )
          ctcfp.feature_count = cnt
          ctcfp.save! if ctcfp.changed?
        rescue Exception => e
          str = "Error in save_to_database in Classifier, word-#{word}, cnt-#{cnt}. Exception: #{e}"
          p str
          BayesLogger.bayes_logger.error str
        end
      end
    end
  end


  def nb_filter_string str
    filtered_str = str.clone
    # Get regexp through all classes for 'Салават Юлаев' case
    TextClass.pluck(:name).each do |tc_name|
      filtered_str.gsub!( Regexp.new(Settings.bayes.regexp[tc_name]), tc_name )
    end
    return filtered_str
  end


  def nb_get_features str
    features = []
    text_classes.each do |tc|
      matched = str.scan( Regexp.new(Settings.bayes.regexp[tc.name]) )
      features += [ tc.name ] * matched.count
    end
    # Add domain only if present some city named feature
    unless features.empty?
      domain = str.scan( Regexp.new( Settings.bayes.regexp["domain"] ) )
      features << domain[0].split("/")[2] unless domain.empty?
    end
    return features
  end


  def naive_bayes_train( features_vector, klass_id )
    @classifier.train( features_vector, klass_id )
  end


  def naive_bayes_classify( features_vector )
    @classifier.classify( features_vector )
  end
end