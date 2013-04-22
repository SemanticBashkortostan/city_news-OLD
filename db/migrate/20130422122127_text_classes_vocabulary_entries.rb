class TextClassesVocabularyEntries < ActiveRecord::Migration
 def change
  	create_table :text_classes_vocabulary_entries do |t|
  	  t.integer :text_class_id      
      t.integer :vocabulary_entry_id      
    end

    add_index :text_classes_vocabulary_entries, [:text_class_id, :vocabulary_entry_id], :name => :voc_entry_tc_index
  end
end
