class CreateClassifierTextClassFeatureProperties < ActiveRecord::Migration
  def up
    create_table :classifier_text_class_feature_properties do |t|
      t.integer :classifier_id
      t.integer :text_class_feature_id
      t.integer :feature_count

      t.timestamps
    end

    add_index :classifier_text_class_feature_properties, [:classifier_id, :text_class_feature_id]
  end


  def down
    drop_table :classifier_text_class_feature_properties
  end
end
