ActiveAdmin.register VocabularyEntry do
  form do |f|
    f.inputs
    f.inputs "Others" do
      f.input :text_classes
    end
    f.actions
  end
end
