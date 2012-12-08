ActiveAdmin.register Feed do

  filter :text_class
  filter :assigned_class
  filter :mark_id, :as => :check_boxes, :collection => Feed.mark_options

  batch_action :delete_class do |selection|
    Feed.find(selection).each do |feed|
      feed.text_class = nil
      feed.save
    end
    redirect_to admin_feeds_path
  end

  batch_action :delete_mark do |selection|
    Feed.find(selection).each do |feed|
      feed.mark_id = nil
      feed.save
    end
    redirect_to admin_feeds_path
  end

  form do |f|
    f.inputs
    f.inputs "Others" do
      f.input :mark_id, :as => :select, :collection => (1..4).to_a
    end
    f.actions
  end

end
