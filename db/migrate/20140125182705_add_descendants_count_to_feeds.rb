class AddDescendantsCountToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :descendants_count, :integer, default: 0

    Feed.where('text_class_id IS NOT NULL').find_each do |feed|
      feed.send(:update_descendants_count)
    end
  end
end
