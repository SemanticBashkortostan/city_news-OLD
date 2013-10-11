class AddAncestryToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :ancestry, :string
    add_column :feeds, :similar_score, :float
    add_index :feeds, :ancestry
  end
end
