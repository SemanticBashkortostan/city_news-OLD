#coding: utf-8

class AddPrepositionalNameToTextClasses < ActiveRecord::Migration
  def up
    add_column :text_classes, :prepositional_name, :string
    name_to_prepositional = {"Уфа" => "Уфы", "Стерлитамак" => "Стерлитамака", "Нефтекамск" => "Нефтекамска", "Ишимбай" => "Ишимбая", "Салават" => "Салавата"}
    name_to_prepositional.each do |k,v|
      tc = TextClass.find_by_name k
      tc.prepositional_name = v
      tc.save!
    end
  end


  def down
    remove_column :text_classes, :prepositional_name
  end
end
