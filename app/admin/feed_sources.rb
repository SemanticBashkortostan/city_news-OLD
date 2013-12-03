ActiveAdmin.register FeedSource do

  member_action :check_availibility, :method => :put do
    feed_source = FeedSource.find(params[:id])
    if feed_source.available?
      notice = "#{feed_source.id} is available"     
    else
      notice = "#{feed_source.id} is NOT available"
    end
    flash[:notice] = notice
    redirect_to :action => :index, :notice => notice
  end  

  index do
    column :id
    column :updated_at
    column :url
    column :active
    column :extractable_main_content
    actions defaults: true do |feed_source|
      link_to 'Is available?', check_availibility_admin_feed_source_path(feed_source), :method => :put
    end
  end

end
