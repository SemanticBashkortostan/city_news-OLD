class Feed < ActiveRecord::Base
  attr_accessible :published_at, :summary, :text_class_id, :title, :url, :text_class, :mark_list

  belongs_to :text_class

  acts_as_taggable_on :marks

  validates :url, :uniqueness => true

  scope :with_text_klass, lambda{ |text_klass_id| where('text_class_id = ?', text_klass_id) }

  before_validation :convert_if_punycode_url
  before_save :strip_html_tags


  def string_for_classifier
    title + " " + summary + " " + "Domain: #{url}"
  end


  def self.fetched_trainers( cnt = 3 )
    scope = tagged_with(["fetched", "production", "classified", "to_train"])
    result = []
    Settings.bayes.klasses.each do |klass_name|
      data = scope.where( :text_class_id => TextClass.find_by_name( klass_name ).id ).limit(cnt)
      return nil if data.count != cnt
      result << data.all
    end
    result.flatten
  end


  protected


  def convert_if_punycode_url
    url.gsub!(/xn--.+xn--p1ai/, SimpleIDN.to_unicode(url.scan(/xn--.+xn--p1ai/).first)) unless url.scan(/xn--.+xn--p1ai/).empty?
  end


  def strip_html_tags
    str = ActionController::Base.helpers.strip_tags( summary )
    self.summary = str.html_safe
    str = ActionController::Base.helpers.strip_tags( title )
    self.title = str.html_safe
  end

end
