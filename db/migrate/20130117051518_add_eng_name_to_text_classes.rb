#coding: utf-8
class AddEngNameToTextClasses < ActiveRecord::Migration
  def up
    add_column :text_classes, :eng_name, :string

    rus = ["Уфа", "Стерлитамак", "Салават", "Ишимбай", "Нефтекамск"]
    eng = ["Ufa", "Sterlitamak", "Salavat", "Ishimbay", "Neftekamsk"]
    rus.count.times do |i|
      tc = TextClass.find_by_name rus[i]
      if tc 
        tc.eng_name = eng[i]
        tc.save!
      end
    end
  end


  def down
    remove_column :text_classes, :eng_name
  end
end
