class AddColumnToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :mark_id, :integer
  end
end
