object @news

node(:per_page) {|m| @pages_data[:per_page] }
node(:pages_count) {|m| @pages_data[:pages_count]}
node(:current_page) {|m| @pages_data[:current_page]}

child :@news do
  attributes :id, :title, :summary, :published_at, :rbcitynews_url
  attributes :url => :legacy_url, :text_class_id => :city_id  
end