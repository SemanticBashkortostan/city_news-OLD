class Classifier < ActiveRecord::Base
  NAIVE_BAYES_NAME = "NaiveBayes"
  SVM_NAME = "SVM"
  TRAIN_TAGS = ["test_train", "dev_train", "was_trainer"]

  attr_accessible :name

  has_many :classifier_text_class_feature_properties, :dependent => :destroy
  has_many :text_class_features, :through => :classifier_text_class_feature_properties


  def train str, klass
    case klass
      when String
        klass_id = TextClass.find_by_name(klass).id
      when Symbol
        klass_id = TextClass.find_by_name(klass).id
      when TextClass
        klass_id = klass.id
      else
        raise ArgumentError
    end

    if is_naive_bayes?
      naive_bayes_train( str, klass_id )
    elsif name[SVM_NAME]
      svm_train( str, klass_id )
    end
  end


  def classify str
    if is_naive_bayes?
      naive_bayes_classify( str )
    elsif name =~ SVM_NAME
      svm_classify( str )
    end
  end


  def save_to_database!

    if is_naive_bayes?
      save_naive_bayes
    end

  end


  # Один раз выгружаем из БД данные о классификаторе( features, klasses, feature properties )
  def preload_classifier( options = {} )
    if is_naive_bayes?
      preload_naive_bayes options
    end
  end


  def text_classes
    TextClass.where :id => text_class_features.pluck(:text_class_id).uniq
  end


  def self.make_from_text_classes( text_klasses, options = {} )
    raise ArgumentError if text_klasses.blank? || options[:name].blank?

    classifier = Classifier.create! :name => options[:name]
    classifier.preload_classifier
    training_feeds = classifier.get_training_feeds(text_klasses)
    training_feeds.each do |text_klass, feeds|
      feeds.each do |feed|
        classifier.train( feed.string_for_classifier, text_klass )
      end
    end
    classifier.save_to_database!
  end


  # Select feeds equal by count for NaiveBayes
  # Returns { TextClass => selected_feeds }
  def get_training_feeds( text_klasses )
    training_feeds_hash = {}
    text_klasses.each do |text_klass|
      training_feeds_hash[text_klass] = text_klass.feeds.tagged_with( TRAIN_TAGS, :any => true )
    end

    feeds_counts = training_feeds_hash.values.collect{|e| e.count}
    if is_naive_bayes? && (feeds_counts.min != feeds_counts.max)
      min_count = feeds_counts.min
      training_feeds_hash.each do |k, v|
        training_feeds_hash[k] = v[0...min_count]
      end
    end

    return training_feeds_hash
  end



  private



  #------------- Naive Bayes Section -------------
  #-----------------------------------------------

  def is_naive_bayes?
    not name[NAIVE_BAYES_NAME].nil?
  end


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


  def naive_bayes_train( str, klass_id )
    @nb.train( str, klass_id )
  end


  def naive_bayes_classify( str )
    @nb.classify str
  end


end
