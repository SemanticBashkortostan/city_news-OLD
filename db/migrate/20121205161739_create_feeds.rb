class CreateFeeds < ActiveRecord::Migration
  def change
    create_table :feeds do |t|
      t.string :title
      t.string :url
      t.text :summary
      t.datetime :published_at
      t.integer :text_class_id

      t.timestamps
    end
  end
end
