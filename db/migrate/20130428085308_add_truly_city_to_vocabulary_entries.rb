class AddTrulyCityToVocabularyEntries < ActiveRecord::Migration
  def change
    add_column :vocabulary_entries, :truly_city, :boolean, :default => false
  end
end
