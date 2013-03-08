class CreateClassifiersFeeds < ActiveRecord::Migration
  def up
    create_table :classifiers_feeds do |t|
      t.integer :classifier_id
      t.integer :feed_id
    end

    add_index :classifiers_feeds, [:classifier_id, :feed_id]
  end

  def down
    drop_table :classifiers_feeds
  end
end

