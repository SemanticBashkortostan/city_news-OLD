class RemoveAssignedClassIdColumnFromFeeds < ActiveRecord::Migration
  def up
    Feed.where('text_class_id IS NULL AND assigned_class_id IS NOT NULL').all.each do |feed|
      feed.text_class_id = feed.assigned_class_id
      feed.mark_list = nil
      feed.save!
    end
    remove_column :feeds, :assigned_class_id
  end

  def down
    add_column :feeds, :assigned_class_id, :integer
  end
end


