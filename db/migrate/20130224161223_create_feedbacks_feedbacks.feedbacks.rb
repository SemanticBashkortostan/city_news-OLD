# This migration comes from feedbacks (originally 20121108115745)
class CreateFeedbacksFeedbacks < ActiveRecord::Migration
  def change
    create_table :feedbacks_feedbacks do |t|
      t.string :topic
      t.text :text
      t.string :email
      t.string :url

      t.timestamps
    end
  end
end
