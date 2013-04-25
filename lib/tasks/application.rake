#coding: utf-8

namespace :application do
  desc "Fully destroy old application state and make reloading WITHOUT destroying existing data"
  task :reload_state => :environment do
    TextClassFeature.destroy_all
    Rake::Task['bayes:init_train'].invoke
  end


  desc "Fill vocabulary( previously need to create dict )"
  task :fill_vocabulary => :environment do
    filename = 'stem_vocabulary_hash'
    raise Exception unless File.exist?(filename)
    text_class_vocabulary = Marshal.load( File.binread(filename) )
    text_class_vocabulary.each do |text_class_id, vocabulary|
      vocabulary.each do |token|
        ve = VocabularyEntry.find_or_create_by_token_and_state token, VocabularyEntry::ACCEPTED_STATE
        ve.text_class_ids << text_class_id
        ve.save!
      end
    end

    Settings.bayes.regexp.downcased.each do |text_class_name, regexp|
      ve = VocabularyEntry.find_or_create_by_token_and_regexp_rule_and_state text_class_name, regexp, VocabularyEntry::ACCEPTED_STATE
      ve.text_classes << TextClass.find_by_name(text_class_name)
      ve.save!
    end
    VocabularyEntry.find_or_create_by_regexp_rule_and_state Settings.bayes.regexp.domain, VocabularyEntry::ACCEPTED_STATE
  end


  desc "Make outlier svm classifier"
  task :make_outlier_svm_classifier => :environment do
    svm = Svm.new
    svm.make_training_and_test_files
    svm.train_model :need_scaling => true, :need_optimizing => true
  end
end