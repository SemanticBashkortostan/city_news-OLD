class AddParametersToClassifier < ActiveRecord::Migration
  #NOTE: After this migration all classifiers remaking needs, 'cause docs_counts and text_classes moves to hstore
  def change
    add_column :classifiers, :parameters, :hstore
  end
end
