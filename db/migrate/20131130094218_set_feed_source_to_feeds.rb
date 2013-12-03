class SetFeedSourceToFeeds < ActiveRecord::Migration
  def up    
    Feed.where('text_class_id is NOT NULL').find_each do |feed|
      p "Error - #{feed.errors.full_messages}" unless feed.save
    end  
  end

  def down
    raise IrreversibleMigration
  end
end
