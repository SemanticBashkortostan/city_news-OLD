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
    p feature_vectors
  end


  protected


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
