class CreateVocabularyEntries < ActiveRecord::Migration
  def change
    create_table :vocabulary_entries do |t|
      t.string :token
      t.string :regexp_rule
      t.integer :state

      t.timestamps
    end
  end
end
