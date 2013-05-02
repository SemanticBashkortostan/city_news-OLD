#coding: utf-8
class Feed < ActiveRecord::Base

  # This constant used to make truly cities tokens more strength in features_for_classifier
  # IF it equal to 1 then it doesn't make sense
  TRULY_MULTIPLIER = 1

  attr_accessible :published_at, :summary, :text_class_id, :title, :url, :text_class, :mark_list

  belongs_to :text_class

  acts_as_taggable_on :marks

  has_many :classified_infos, :class_name => 'FeedClassifiedInfo', :dependent => :destroy
  has_many :classifiers, :through => :classified_infos

  validates :url, :uniqueness => true
  validate :summary_or_title_presence

  scope :without_uncorrect_tags, tagged_with(Classifier::UNCORRECT_DATA_TAGS, :exclude => true )
  scope :with_text_klass, lambda{ |text_klass_id| without_uncorrect_tags.where('text_class_id = ?', text_klass_id) }
  scope :unclassified_fetched, tagged_with(["fetched", "production"], :match_all => true).without_uncorrect_tags.where(:text_class_id => nil)
  scope :was_trainers, lambda{ |classifier_id| includes(:classifiers).where(:classifiers_feeds => {:classifier_id => classifier_id}) }

  before_validation :convert_if_punycode_url
  before_save :strip_html_tags
  before_save :set_default_published_at


  def self.fetched_trainers( cnt, text_classes, cl_id )
    trained_feed_ids = was_trainers(cl_id).collect{|train_feed| train_feed.id}
    scope = where("feeds.id not in (?)", trained_feed_ids).tagged_with(["fetched", "production", "classified", "to_train"])
    result = []
    text_classes.each do |tc|
      data = scope.where( :text_class_id => tc.id ).limit(cnt)
      return nil if data.count != cnt
      result << data.all
    end
    result.flatten
  end


  CachedFeed = Struct.new( :id, :feature_vectors_for_relation_extraction, :features_for_text_classifier, :mark_list, :text_class )
  # Get cached feeds or create them if they not exists
  # options - +:filename+ -cached filename, default is 'default_feeds_cache' and saved into tmp/cache;
  #@param     +:feeds:+ - feeds which will save into cache; default is all Feeds with text classes
  #@param     +:recreate+ - if true then cache will be recreate
  def self.cached( options={} )
    options[:filename] ||= "default_feeds_cache"
    options[:need_re] ||= true
    filename = "tmp/cache/#{options[:filename]}"
    return FileMarshaling::marshal_load(filename) if File.exist?( filename ) && !options[:recreate]

    feeds = Set.new
    to_cache_feeds = options[:feeds]
    to_cache_feeds ||= Feed.includes(:text_class, :marks).where(:text_class_id => TextClass.all).all
    to_cache_feeds.each do |feed|
      for_relation_extraction = feed.feature_vectors_for_relation_extraction if options[:need_re]
      feeds << CachedFeed.new( feed.id, for_relation_extraction, feed.features_for_text_classifier,
                     feed.mark_list, feed.text_class )
    end
    FileMarshaling::marshal_save(filename, feeds)
  end


  def string_for_classifier
    title.to_s + " . " + summary.to_s + " . " + "Domain: #{self.domain}"
  end


  def domain
    url.split("/")[2]
  end


  # Retrun all possible feature vectors for relation extraction
  def feature_vectors_for_relation_extraction()
    return [] unless text_class
    raw_feature_vectors = get_raw_feature_vectors   
    city_features, named_features = city_and_named_features(raw_feature_vectors)
    return [] unless city_features.present? && named_features.present?
    get_feature_vectors_for_relation_extraction( city_features, named_features )
  end


  # Return feature vector for text classifier
  def features_for_text_classifier(options={})
    raw_feature_vectors = get_raw_feature_vectors( :for_text_classifier => true )
    fvs = city_and_named_features(raw_feature_vectors).flatten
    fvs = fvs.collect{|e| WordProcessor.stem(e[:token], e[:quoted]) }
    filtered_fvs = []
    fvs.each do |word|
      if word.length > 2
        filtered_fvs << word if VocabularyEntry.has?( word )
        filtered_fvs += [ VocabularyEntry.is_truly?(word) ]*TRULY_MULTIPLIER  if VocabularyEntry.is_truly?(word)
      end
    end
    feature_vector = filtered_fvs + VocabularyEntry.words_matches_rules( string_for_classifier )
    return [] if feature_vector.count == 1 && !options[:debug]
    feature_vector
  end



  protected



  #NOTE: Feature is city if he has text_class_id. text_class_id only set for the token which satisfy to city_regexp
  def city_and_named_features(raw_feature_vectors)
    city_features = []
    named_features = []
    raw_feature_vectors.each do |feature_vector|
      if feature_vector[:text_class_id]
        city_features << feature_vector
      else
        if feature_vector[:comma] 
          feature_vector[:token].split(",").each do |uncomma_word|
            cloned_fv = feature_vector.clone 
            cloned_fv[:token] = uncomma_word
            named_features << cloned_fv
          end
        else
          named_features << feature_vector
        end
      end      
    end
    return [city_features, named_features]
  end


  def get_feature_vectors_for_relation_extraction city_features, named_features
    vectors = []
    has_other_cities = city_features.find{|e| e[:text_class_id] > 0 && e[:text_class_id] != text_class.id }.present?
    city_features.each do |city_hash|
      named_features.each do |named_hash|
        in_one_sent = city_hash[:sent_ind] == named_hash[:sent_ind]
        distance = (city_hash[:token_pos] - named_hash[:token_pos]).abs        
        tc_word_position = ( (city_hash[:token_pos]+1)*city_hash[:sent_ind] > (named_hash[:token_pos]+1)*named_hash[:sent_ind] )
        tc_same_as_feed = (city_hash[:text_class_id] == text_class.id)

        # *distance* needs to be discretized!
        feature_vector = {
                          :text_class_id => city_hash[:text_class_id], :tc_is_first_token => city_hash[:is_first_token], :tc_token => city_hash[:token],
                          :tc_right_context => city_hash[:right_context], :tc_left_context => city_hash[:left_context], :tc_quoted => city_hash[:quoted],
                          :tc_stem => WordProcessor.stem(city_hash[:token], city_hash[:quoted]),

                          :has_other_cities => has_other_cities, :in_one_sent => in_one_sent, :distance => distance, :tc_word_position => tc_word_position,
                          :tc_same_as_feed => tc_same_as_feed, :is_main_class => city_hash[:is_main_class],

                          :ne_is_first_token => named_hash[:is_first_token], :ne_token => named_hash[:token], :ne_right_context => named_hash[:right_context], 
                          :ne_left_context => named_hash[:left_context], :ne_quoted => named_hash[:quoted], 
                          :ne_stem => WordProcessor.stem( named_hash[:token], named_hash[:quoted] )
                       }
        vectors << feature_vector
      end
    end
    return vectors
  end


  def get_raw_feature_vectors options={}
    if text_class && !options[:for_text_classifier]
      city_lexer = CityLexer.new({ :text_class_id => text_class.id, :main_city_regexp => Regexp.new( VocabularyEntry.make_regexp_for_truly_entries(text_class_id)[0] ),
                                   :other_classes_regexp => Regexp.new(VocabularyEntry.make_regexp_for_truly_entries(text_class_id, :for_other_cities => true)[0]) } )
      city_lexer.city_news_mode = options[:city_news_mode] || 1
    else
      city_lexer = CityLexer.new
    end

    feature_vectors = []
    sentences = split_text_to_sentences(title.to_s + " . " + summary.to_s)
    sentences.each_with_index do |sentence, ind|
      sentence.gsub!(/(&laquo;)|(&raquo;)|(&quot;)/, '"')      
      sentence.gsub!(/[()]/, " ")      
      feature_vectors << city_lexer.get_tokens_hash( sentence, :sent_ind => ind ).values
    end
    return feature_vectors.flatten
  end


  #NOTE: Make text splitting more intellectualy. 'cause this naive case not work for human names, streets, etc.
  def split_text_to_sentences text
    sentence_split_regexp = /[.!?]/
    text.split(sentence_split_regexp)
  end


  def summary_or_title_presence
    errors.add(:base, "Title and summary is not exist") if summary.blank? && title.blank?
  end


  def convert_if_punycode_url
    url.gsub!(/xn--.+xn--p1ai/, SimpleIDN.to_unicode(url.scan(/xn--.+xn--p1ai/).first)) unless url.scan(/xn--.+xn--p1ai/).empty?
  end


  def strip_html_tags
    if summary.present?
      str = ActionController::Base.helpers.strip_tags( summary )
      self.summary = str.html_safe
    end

    if title.present?
      str = ActionController::Base.helpers.strip_tags( title )
      self.title = str.html_safe
    end
  end


  def set_default_published_at
    self.published_at ||= Time.now - 30.minutes
  end

end
