class AddAssignedClassColumnToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :assigned_class_id, :integer
  end
end
