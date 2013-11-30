class AddFeedSourceIdToFeeds < ActiveRecord::Migration
  def change    
    add_column :feeds, :feed_source_id, :integer
    add_index :feeds, :feed_source_id
    add_index :feed_sources, :url
  end
end
