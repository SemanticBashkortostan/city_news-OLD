class Classifier < ActiveRecord::Base
  NAIVE_BAYES_NAME = "NaiveBayes"
  SVM_NAME = "SVM"
  TRAIN_TAGS = ["test_train", "dev_train", "was_trainer"]
  TEST_TAGS  = ["dev_test"]

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


  def extract_class!( text_class )
    ClassifierTextClassFeatureProperty.where( :classifier_id => self.id, :text_class_feature_id => self.text_class_features.where( :text_class_id => text_class ) ).destroy_all
    rebuild_classifier
    save_to_database!
  end


  # Test classifier by fetching feeds with specific tags
  # +options[:tags]+ - list of tags, like ["dev_test", "production"]
  # +options[:tags_options]+ - parameter which responses how to fetch, like {:match_all => true} or {:any => true}
  def test( options={} )
    test_feeds = get_testing_feeds( options[:tags], options[:tags_options], options[:feeds_count], options[:is_random])
    confusion_matrix = build_confusion_matrix( test_feeds )
    print_classifier_performance confusion_matrix
  end


  def text_classes
    TextClass.where :id => text_class_features.pluck(:text_class_id).uniq
  end


  # Select feeds. It will be equal by count for NaiveBayes.
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


  # Return testing feeds which requires to special conditions as such as
  # +tags+, +tags_options+, +feeds_count+, +is_random+
  def get_testing_feeds( tags=nil, tags_options=nil, feeds_count = nil, is_random = false )
    tags ||= TEST_TAGS
    tags_options ||= {}
    feeds_count ||= ( train_set_count * 0.2 ).ceil
    testing_feeds = []
    text_classes.each do |tc|
      scope = Feed.where(:text_class_id => tc).tagged_with( tags, tags_options )
      testing_feeds << ( (is_random == true ? scope.order("RANDOM()").limit(feeds_count) : scope.limit(feeds_count)) )
    end
    return testing_feeds.flatten
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

    classifier.preload_classifier
    return classifier
  end



  private



  def rebuild_classifier
    @nb = NaiveBayes::NaiveBayes.new if is_naive_bayes?
    get_training_feeds( text_classes ).each do |tc, feeds|
      feeds.each do |feed|
        train( feed.string_for_classifier, tc )
      end
    end
  end


  def build_confusion_matrix( feeds )
    confusion_matrix = {}
    feeds.each do |feed|
      str = feed.string_for_classifier
      classified = TextClass.find( classify( str )[:class] ).name
      confusion_matrix[feed.text_class.name] ||= {}
      confusion_matrix[feed.text_class.name][classified] = confusion_matrix[feed.text_class.name][classified].to_i + 1
    end
    return confusion_matrix
  end


  include Statistic
  #TODO: Записываем id для которых тестировали и всё остальное в файл!
  def print_classifier_performance confusion_matrix
    accuracy = accuracy( confusion_matrix )
    p "Confusion Matrix: #{confusion_matrix}"
    p "Accuracy: #{accuracy}"
    text_classes.pluck(:name).each{ |klass_name| p ["F-measure for #{klass_name} is ", f_measure(confusion_matrix, klass_name)] }
  end


  # Training set count for each class
  def train_set_count
    if is_naive_bayes?
      @nb.export[:docs_count].values.min
    end
  end


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


  def naive_bayes_filter? str
    return true if Rails.env == "test"
    text_classes.pluck(:name).each do |tc_name|
      return true if str =~ Settings.bayes.regexp(tc_name)
    end
    return false
  end


  def naive_bayes_train( str, klass_id )
    @nb.train( str, klass_id ) if naive_bayes_filter?( str )
  end


  def naive_bayes_classify( str )
    @nb.classify( str ) if naive_bayes_filter?( str )
  end


end
