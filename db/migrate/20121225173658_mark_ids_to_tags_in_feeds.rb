class MarkIdsToTagsInFeeds < ActiveRecord::Migration
  def up
    Feed.where('mark_id is not null').all.each do |feed|
      feed.mark_list = feed.mark
      feed.save!
    end

    remove_column :feeds, :mark_id
  end


  def down
    add_column :feeds, :mark_id
    puts "Unreversable migration!!!"
  end
end
