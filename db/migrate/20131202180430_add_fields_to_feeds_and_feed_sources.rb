class AddFieldsToFeedsAndFeedSources < ActiveRecord::Migration
  def change
    add_column :feed_sources, :extractable_main_content, :boolean
    add_column :feed_sources, :active, :boolean, :default => true
    add_index :feed_sources, :extractable_main_content
    add_index :feed_sources, :active

    add_column :feeds, :main_html_content, :text
  end
end
