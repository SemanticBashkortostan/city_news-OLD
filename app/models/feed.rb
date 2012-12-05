class Feed < ActiveRecord::Base
  attr_accessible :published_at, :summary, :text_class_id, :title, :url

  belongs_to :text_class
end
