class Feed < ActiveRecord::Base
  attr_accessible :published_at, :summary, :text_class_id, :title, :url, :text_class

  belongs_to :text_class
  belongs_to :assigned_class, :class_name => 'TextClass', :foreign_key => 'assigned_class_id'

  validate :url, :uniqueness => true


  def mark
    case mark_id
      when 1 then "Training"
      when 2 then "Development Test Set"
      when 3 then "Test Set"
      else        "Unmarked"
    end
  end
end
