class CreateFeedClassifiedInfos < ActiveRecord::Migration
  def change
    create_table :feed_classified_infos do |t|
      t.integer :feed_id
      t.integer :classifier_id
      t.integer :text_class_id
      t.boolean :to_train
      t.float :score

      t.timestamps
    end

    add_index :feed_classified_infos, [:feed_id]
    add_index :feed_classified_infos, [:feed_id, :classifier_id]
  end
end
