class Feed < ActiveRecord::Base
  attr_accessible :published_at, :summary, :text_class_id, :title, :url, :text_class, :assigned_class_id, :mark_list

  belongs_to :text_class
  belongs_to :assigned_class, :class_name => 'TextClass', :foreign_key => 'assigned_class_id'

  acts_as_taggable_on :marks

  validates :url, :uniqueness => true


  def training_string
    title + " " + summary + " " + "Domain: #{url}"
  end

  # Tags: train, dev_test
end
