class CreateDocsCounts < ActiveRecord::Migration
  def change
    create_table :docs_counts do |t|
      t.integer :classifier_id
      t.integer :text_class_id
      t.integer :docs_count, :default => 0
    end

    add_index :docs_counts, :classifier_id
    add_index :docs_counts, :text_class_id
  end
end
