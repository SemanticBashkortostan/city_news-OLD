class AddUpdatedAtIndexToFeeds < ActiveRecord::Migration
  def change
    add_index :feeds, :updated_at
  end
end
