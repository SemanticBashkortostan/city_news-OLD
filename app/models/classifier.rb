class Classifier < ActiveRecord::Base
  NAIVE_BAYES_NAME = "NaiveBayes"
  SVM_NAME = "SVM"

  attr_accessible :name

  has_many :classifier_text_class_feature_properties, :dependent => :destroy
  has_many :text_class_features, :through => :classifier_text_class_feature_properties


  def train str, klass_str
    if name[NAIVE_BAYES_NAME]
      naive_bayes_train( str, klass_str )
    elsif name[SVM_NAME]
      svm_train( str, klass_str )
    end
  end


  def classify str
    if name[NAIVE_BAYES_NAME]
      naive_bayes_classify( str )
    elsif name =~ SVM_NAME
      svm_classify( str )
    end
  end


  def save_to_database!

    if name[NAIVE_BAYES_NAME]
      save_naive_bayes
    end

  end


  # Один раз выгружаем из БД данные о классификаторе( features, klasses, feature properties )
  def preload_classifier( options = {} )
    if name[NAIVE_BAYES_NAME]
      preload_naive_bayes options
    end
  end


  def text_classes
    TextClass.where :id => text_class_features.pluck(:text_class_id).uniq
  end



  private



  #------------- Naive Bayes Section -------------
  #-----------------------------------------------


  def preload_naive_bayes options
    @nb = NaiveBayes::NaiveBayes.new
    nb_data = ClassifierTextClassFeatureProperty.import_to_naive_bayes( self.id ).merge(options)
    @nb.import!( nb_data[:docs_count], nb_data[:words_count], nb_data[:vocabolary]  )
  end


  def save_naive_bayes
    klass_words_count = @nb.export[:words_count]
    klass_words_count.each do |klass_id, words_count|
      words_count.each do |word, cnt|
        begin
          tcf =  TextClassFeature.find_or_create_by_text_class_id_and_feature_id( klass_id, Feature.find_or_create_by_token( word ).id )
          self.text_class_features << tcf
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


  def naive_bayes_train( str, klass_str )
    @nb.train( str, TextClass.find_by_name( klass_str ).id )
  end


  def naive_bayes_classify( str )
    @nb.classify str
  end


end
