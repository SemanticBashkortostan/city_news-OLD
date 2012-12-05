class CreateTextClassesFeatures < ActiveRecord::Migration
  def up
    create_table :text_classes_features do |t|
      t.integer :text_class_id
      t.integer :feature_id
    end
    add_index :text_classes_features, [:text_class_id, :feature_id]
    add_index :text_classes_features, [:feature_id, :text_class_id]

  end

  def down
    drop_table :text_classes_features
  end
end
