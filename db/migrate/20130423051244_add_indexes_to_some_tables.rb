class AddIndexesToSomeTables < ActiveRecord::Migration
  def change
    add_index :vocabulary_entries, :token
    add_index :vocabulary_entries, [:state, :token]
    add_index :vocabulary_entries, [:state, :regexp_rule]
  end
end
