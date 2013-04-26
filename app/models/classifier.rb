class Classifier < ActiveRecord::Base
  include ClassifierNaiveBayes
  include ClassifierPerformance

  NAIVE_BAYES_NAME = "NaiveBayes"
  ROSE_NAIVE_BAYES_NAME = "ROSE-MNB"

  TRAIN_TAGS = ["test_train", "dev_train", "was_trainer", "to_train"]

  UNCORRECT_DATA_TAGS = ["uncorrect_data", "uncorrect_classified", "several_class"]

  OTHER_TEXT_CLASS = 500

  attr_accessible :name

  has_many :classifier_text_class_feature_properties, :dependent => :destroy
  has_many :text_class_features, :through => :classifier_text_class_feature_properties

  has_many :feeds_info, :class_name => 'FeedClassifiedInfo'
  has_many :train_feeds, :through => :feeds_info, :source => :feed

  serialize :parameters, ActiveRecord::Coders::Hstore

  attr_reader :class_id_for_rose


  def train feed, klass
    case klass
      when String
        klass_id = TextClass.find_by_name(klass).id
      when Symbol
        klass_id = TextClass.find_by_name(klass).id
      when TextClass
        klass_id = klass.id
      when Numeric
        klass_id = klass
      else
        raise ArgumentError
    end

    features_vector = get_features_vector( feed )
    if features_vector.empty?
      p ["EXCEPTION", feed, klass]
      DevelopmentLogger.logger.error ["Empty feature vector in Classifier#train!!!", feed, klass, features_vector]
      return nil
      #raise Exception
    end

    self.docs_counts = {:text_class_id => klass_id, :count => docs_counts(klass_id) + 1}
    add_to_text_classes klass_id

    case
      when is_naive_bayes?
        naive_bayes_train( features_vector, klass_id )
      when is_rose_naive_bayes?
        rose_naive_bayes_train( features_vector, klass_id )
    end
  end


  def classify feed
    features_vector = get_features_vector( feed )
    return nil if features_vector.empty?
    case
      when is_naive_bayes?
        naive_bayes_classify( features_vector )
      when is_rose_naive_bayes?
        rose_naive_bayes_classify( features_vector )
    end
  end


  def extract_class!( text_class )
    classifier_text_class_feature_properties.where( :text_class_feature_id => self.text_class_features.where( :text_class_id => text_class ) ).destroy_all
    delete_from_text_classes(text_class)
    rebuild_classifier
    save_to_database!
  end


  # Select feeds. It will be equal by count for NaiveBayes.
  # Returns { TextClass => selected_feeds }
  def get_training_feeds
    training_feeds_hash = {}
    if is_rose_naive_bayes?
      raise Exception if text_classes.count > 1
      main_text_class = text_classes.first
      other_text_class = OTHER_TEXT_CLASS

      training_feeds_hash[main_text_class] = main_text_class.feeds.tagged_with( TRAIN_TAGS, :any => true )
      training_feeds_hash[other_text_class] = Feed.tagged_with( TRAIN_TAGS, :any => true ).where(:text_class_id => TextClass.all - [main_text_class])
    else
      text_classes.each do |text_klass|
        training_feeds_hash[text_klass] = text_klass.feeds.tagged_with( TRAIN_TAGS, :any => true )
      end
    end

    feeds_counts = training_feeds_hash.values.collect{|e| e.count}
    if is_naive_bayes? && (feeds_counts.min != feeds_counts.max)
      min_count = feeds_counts.min
      training_feeds_hash.each do |k, v|
        training_feeds_hash[k] = v.limit(min_count)
      end
    end

    return training_feeds_hash
  end


  def save_to_database!
    if is_naive_bayes?
      save_naive_bayes
    elsif is_rose_naive_bayes?
      save_rose_naive_bayes
    end
    save!
    reload
  end


  # Один раз выгружаем из БД данные о классификаторе( features, klasses, feature properties )
  def preload_classifier( options = {} )
    if is_naive_bayes?
      preload_naive_bayes options
    elsif is_rose_naive_bayes?
      preload_rose_naive_bayes options
    end
  end

  # +options+ description:
  # options[:name] - name of classifier
  # For ROSE-MNB pass only one class 'cause it work by one vs all scheme
  # +text_classes+ - should be an array
  def self.make_from_text_classes( text_klasses, options = {} )
    raise ArgumentError if text_klasses.blank? || options[:name].blank?

    classifier = Classifier.create! :name => options[:name]
    classifier.text_classes = text_klasses
    classifier.save!
    classifier.reload
    training_feeds_hash = classifier.get_training_feeds
    if classifier.is_rose_naive_bayes?
      duplicate_info = classifier.get_duplicate_klass_and_count(training_feeds_hash)
      classifier.preload_classifier :duplicate_info => duplicate_info
    else
      classifier.preload_classifier
    end
    training_feeds_hash.each do |text_klass, feeds|
      feeds.each do |feed|
        classifier.train( feed, text_klass )
        classifier.train_feeds << feed
      end
    end
    classifier.save_to_database!

    classifier.preload_classifier
    return classifier
  end


  #TODO:HACK:FUCK: Now code is not clear and we get some ambiguity and code repeating in Classifier
  def get_features_vector feed
    return feed if Rails.env == "test" && feed.is_a?(String)
    return feed.string_for_classifier if Rails.env == "test" && feed.is_a?(Feed)

    if is_naive_bayes?
      filtered_str = nb_filter_string( feed.string_for_classifier )
      return nb_get_features( filtered_str )
    elsif is_rose_naive_bayes?
      return feed.features_for_text_classifier
    end
  end


  def form_docs_counts_hash
    {:docs_count => Hash[text_classes.collect{|tc| tc.is_a?(TextClass) ? [tc.id, docs_counts(tc.id)] : [tc, docs_counts(tc)]  }]}
  end


  def vocabulary
    filename = 'big_vocabulary'
    @vocabulary ||= Marshal.load( File.binread(filename) )
    return @vocabulary
  end


    #---------- HSTORE - actions --------------------------------------------------
  def docs_counts(text_class_id)
    parameters["docs_counts_#{text_class_id}"].to_i
  end

  # +couple+ - hash like {:text_class_id => xx, :count => xx}
  def docs_counts=(couple)
    parameters["docs_counts_#{couple[:text_class_id]}"] = couple[:count]
  end


  def text_classes
    return [] if parameters["text_classes"].blank?
    tcs = TextClass.where :id => JSON.parse(parameters["text_classes"].to_s)
    tcs << OTHER_TEXT_CLASS if JSON.parse(parameters["text_classes"].to_s).include?(OTHER_TEXT_CLASS)
    tcs
  end


  def text_classes=(arr)
    if arr[0].is_a? TextClass
      parameters["text_classes"] = arr.collect{|e| e.id}
    else
      parameters["text_classes"] = arr
    end
  end


  def add_to_text_classes(elem)
    parameters["text_classes"] ||= [] #NOTE: Need move into initialize
    parameters["text_classes"].is_a?( String ) ? arr = JSON.parse(parameters["text_classes"]).to_set : arr = parameters["text_classes"].to_set
    arr << elem
    parameters["text_classes"] = arr.to_a
  end


  def delete_from_text_classes(text_class)
    tcs = text_classes
    tcs.delete(text_class)
    self.text_classes = tcs
    destroy_key(:parameters, "docs_counts_#{text_class.id}")
  end
  #-----------------end of--HSTORE-actions --------------------------------------------------


  def get_duplicate_klass_and_count(training_feeds_hash)
    training_feeds_count = training_feeds_hash.collect { |k, v| v.count }
    duplicate_klass = training_feeds_hash.min_by { |k, v| v.count }.first
    duplicate_klass = duplicate_klass.id if duplicate_klass.is_a?( TextClass )
    duplicate_count = (training_feeds_count[0] - training_feeds_count[1]).abs
    return [duplicate_klass, duplicate_count]
  end



  def is_naive_bayes?
    not name[NAIVE_BAYES_NAME].nil?
  end


  def is_rose_naive_bayes?
    not name[ROSE_NAIVE_BAYES_NAME].nil?
  end


  def debug_classifier
    @classifier
  end


  private


  def rebuild_classifier
    training_feeds_hash = get_training_feeds
    if is_naive_bayes?
      @classifier = NaiveBayes::NaiveBayes.new
    elsif is_rose_naive_bayes?
      duplicate_klass, duplicate_count = get_duplicate_klass_and_count(training_feeds_hash)
      @classifier = NaiveBayes::NaiveBayes.new 1.0, :rose, {:rose => {:duplicate_klass => duplicate_klass, :duplicate_count => duplicate_count}}
    end
    training_feeds_hash.each do |tc, feeds|
      feeds.each do |feed|
        train( feed, tc )
      end
    end
  end


  def filter_by_vocabulary( features )
    filtered = []
    not_in_voc = []
    return filtered if features.blank?
    features.each do |f|
      if f.is_a?(Array)
        filtered += f
      elsif vocabulary.include?( f )
        filtered << f
      else
        not_in_voc << f
      end
    end
    return filtered
  end


  def rose_naive_bayes_train( features_vector, klass_id )
    @classifier.train( features_vector, klass_id )
  end


  def rose_naive_bayes_classify(features_vector)
    @classifier.classify( features_vector )
  end


  def save_rose_naive_bayes
    save_naive_bayes
    parameters[:rose_duplicate_count] = @classifier.export[:rose_duplicate_count].to_a.first.to_json
    parameters[:average_document_words] = @classifier.export[:average_document_words].to_json
  end


  #TODO: Необходимо продумать случай с active learning для ROSE NB


  def preload_rose_naive_bayes options
    if options[:duplicate_info]
      duplicate_class, duplicate_count = options[:duplicate_info]
    else
      duplicate_class, duplicate_count = JSON.parse(parameters["rose_duplicate_count"])
    end
    @class_id_for_rose = text_classes.find{ |e| e.is_a?(TextClass) }.id
    @classifier = NaiveBayes::NaiveBayes.new 1.0, :rose, {:rose => { :duplicate_klass => duplicate_class, :duplicate_count => duplicate_count} }
    nb_data = import_naive_bayes_data(options)
    nb_data[:average_document_words] = Hash[JSON.parse(parameters["average_document_words"]).map{|(k,v)| [k.to_i, v]}] if parameters["average_document_words"]
    @classifier.import!( nb_data[:docs_count], nb_data[:words_count], nb_data[:vocabolary], { :average_document_words => nb_data[:average_document_words] }  )
  end


  # Training set count for each class
  def train_set_count
    if is_naive_bayes?
      @classifier.export[:docs_count].values.min
    end
  end

end
