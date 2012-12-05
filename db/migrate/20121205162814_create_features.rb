class CreateFeatures < ActiveRecord::Migration
  def change
    create_table :features do |t|
      t.string :token

      t.timestamps
    end
  end
end
