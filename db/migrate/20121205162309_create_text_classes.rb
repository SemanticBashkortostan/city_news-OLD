class CreateTextClasses < ActiveRecord::Migration
  def change
    create_table :text_classes do |t|
      t.string :name

      t.timestamps
    end
  end
end
