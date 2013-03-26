#coding: utf-8
class Feed < ActiveRecord::Base
  attr_accessible :published_at, :summary, :text_class_id, :title, :url, :text_class, :mark_list

  belongs_to :text_class

  acts_as_taggable_on :marks

  has_and_belongs_to_many :classifiers

  validates :url, :uniqueness => true
  validate :summary_or_title_presence

  scope :without_uncorrect_tags, tagged_with(Classifier::UNCORRECT_DATA_TAGS, :exclude => true )
  scope :with_text_klass, lambda{ |text_klass_id| without_uncorrect_tags.where('text_class_id = ?', text_klass_id) }
  scope :unclassified_fetched, tagged_with(["fetched", "production"], :match_all => true).without_uncorrect_tags.where(:text_class_id => nil)
  scope :was_trainers, lambda{ |classifier_id| includes(:classifiers).where(:classifiers_feeds => {:classifier_id => classifier_id}) }


  searchable do
    text :title, :stored => true    
    text :summary, :stored => true    
  end


  before_validation :convert_if_punycode_url
  before_save :strip_html_tags
  before_save :set_default_published_at


  def string_for_classifier
    title.to_s + " " + summary.to_s + " " + "Domain: #{url}"
  end


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


  def feature_vectors_for_re
    raw_feature_vectors = get_raw_feature_vectors   
    city_features, named_features = city_and_named_features(raw_feature_vectors)
    get_features_for_classifier( city_features, named_features )
  end



  protected



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


  def get_features_for_classifier city_features, named_features
    classifier_features = []
    has_other_cities = city_features.find{|e| e[:text_class_id] == text_class.id} && city_features.find{|e| e[:text_class_id] > 0 && e[:text_class_id] != text_class.id }
    city_features.each do |city_hash|
      named_features.each do |named_hash|
        in_one_sent = city_hash[:sent_ind] == named_hash[:sent_ind]
        distance = (city_hash[:token_pos] - named_hash[:token_pos]).abs        
        tc_word_position = ( (city_hash[:token_pos]+1)*city_hash[:sent_ind] > (named_hash[:token_pos]+1)*named_hash[:sent_ind] )
        tc_same_as_feed = (city_hash[:text_class_id] == text_class.id)

        feature_hash = {           
                          :text_class_id => city_hash[:text_class_id], :tc_is_first_token => city_hash[:is_first_token], :tc_token => city_hash[:token],
                          :tc_right_context => city_hash[:right_context], :tc_left_context => city_hash[:left_context], :tc_quoted => city_hash[:quoted],

                          :has_other_cities => has_other_cities, :in_one_sent => in_one_sent, :distance => distance, :tc_word_position => tc_word_position,
                          :tc_same_as_feed => tc_same_as_feed,

                          :ne_is_first_token => named_hash[:is_first_token], :ne_token => named_hash[:token], :ne_right_context => named_hash[:right_context], 
                          :ne_left_context => named_hash[:left_context], :ne_quoted => named_hash[:quoted]  
                       }
        classifier_features << feature_hash
      end
    end
    return classifier_features
  end


  def get_raw_feature_vectors
    other_cities_regexp = Hash[(TextClass.pluck(:name) - [text_class.name]).map{|e| [TextClass.find_by_name(e).id, Regexp.new(Settings.bayes.regexp[e]) ]}]
    city_lexer = CityLexer.new({ :text_class_id => text_class.id, :main_city_regexp => Regexp.new( Settings.bayes.regexp[text_class.name] ), 
                                 :other_classes => other_cities_regexp } )
    city_lexer.city_news_mode = 1

    sentence_split_regexp = /[.!?]/
    text = title.to_s + "." + summary.to_s
            
    feature_vectors = []
    text.split(sentence_split_regexp).each_with_index do |sentence, ind|
      feature_vectors << city_lexer.get_tokens_hash( sentence, :sent_ind => ind )
    end
    return feature_vectors
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
