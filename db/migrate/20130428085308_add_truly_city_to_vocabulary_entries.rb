class AddTrulyCityToVocabularyEntries < ActiveRecord::Migration
  def change
    add_column :vocabulary_entries, :truly_city, :boolean, :default => false
    VocabularyEntry.all.each do |ve|
      ve.truly_city ||= false
      ve.save! if ve.changed?
    end
  end
end
