class CreateTextClassesFeatures < ActiveRecord::Migration
  def up
    create_table :text_class_features do |t|
      t.integer :text_class_id
      t.integer :feature_id
      t.integer :feature_count
    end
    add_index :text_class_features, [:text_class_id, :feature_id]
    add_index :text_class_features, [:feature_id, :text_class_id]

  end

  def down
    drop_table :text_class_features
  end
end
