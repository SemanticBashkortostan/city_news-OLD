ActiveAdmin.register Feed do

  filter :text_class
  filter :assigned_class
  filter :taggings_tag_name, :as => :check_boxes, :collection => proc { Feed.mark_counts.map{|t| t.name} }

  batch_action :delete_class do |selection|
    Feed.find(selection).each do |feed|
      feed.text_class = nil
      feed.save
    end
    redirect_to admin_feeds_path
  end


  index do
    column :id
    column :title
    column :url do |feed|
      link_to feed.url, feed.url
    end
    column :summary
    column :mark_list
    column :text_class
    column :published_at
    column :created_at
    default_actions
  end

  form do |f|
    f.inputs
    f.inputs "Others" do
      f.input :mark_list
    end
    f.actions
  end

end
