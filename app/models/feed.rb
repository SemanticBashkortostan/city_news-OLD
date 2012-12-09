class Feed < ActiveRecord::Base
  attr_accessible :published_at, :summary, :text_class_id, :title, :url, :text_class, :mark_id, :assigned_class_id

  belongs_to :text_class
  belongs_to :assigned_class, :class_name => 'TextClass', :foreign_key => 'assigned_class_id'

  validates :url, :uniqueness => true

  before_save :set_mark


  TRAINING = 1
  DEV_TEST = 2
  TEST = 3
  UNMARKED = 4
  def mark
    case mark_id
      when TRAINING then "Training"
      when DEV_TEST then "Development Test Set"
      when TEST then "Test Set"
      else        "Unmarked"
    end
  end

  def self.mark_options
    {"Training" => TRAINING, "Development Test" => DEV_TEST, "Test" => TEST, "Unmarked" => UNMARKED}
  end


  protected


  def set_mark
    mark_id = UNMARKED
  end

end
