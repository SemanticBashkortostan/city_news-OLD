class Feed < ActiveRecord::Base
  attr_accessible :published_at, :summary, :text_class_id, :title, :url, :text_class, :assigned_class_id, :mark_list

  belongs_to :text_class
  belongs_to :assigned_class, :class_name => 'TextClass', :foreign_key => 'assigned_class_id'

  acts_as_taggable_on :marks

  validates :url, :uniqueness => true

  before_save :check_punycode_url, :strip_html_tags


  def training_string
    title + " " + summary + " " + "Domain: #{url}"
  end


  protected


  def check_punycode_url
    url.gsub!(/xn--.+xn--p1ai/, SimpleIDN.to_unicode(url.scan(/xn--.+xn--p1ai/).first)) unless url.scan(/xn--.+xn--p1ai/).empty?
  end


  def strip_html_tags
    self.summary = ActionController::Base.helpers.strip_tags( summary )
    self.title = ActionController::Base.helpers.strip_tags( title )
  end

  # Tags: train, dev_test
end
