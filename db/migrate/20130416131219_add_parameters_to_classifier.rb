class AddParametersToClassifier < ActiveRecord::Migration
  def change
    add_column :classifiers, :parameters, :hstore
  end
end
