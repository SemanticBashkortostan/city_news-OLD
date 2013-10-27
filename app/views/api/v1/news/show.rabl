object @news_entry

child :@news_entry do
  attributes :id, :title, :summary, :published_at, :rbcitynews_url
  attributes :url => :legacy_url, :text_class_id => :city_id
  attributes :has_children? => :has_similar_news
  node(:similar_news_ids){|feed| feed.descendants.collect{|e| e.id}}
end