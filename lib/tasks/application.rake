#coding: utf-8

namespace :application do
  desc "Fully destroy old application state and make reloading WITHOUT destroying existing data"
  task :reload_state => :environment do
    TextClassFeature.destroy_all
    Rake::Task['bayes:init_train'].invoke
  end


  desc "Fill vocabulary( previously dict needs  )"
  task :fill_vocabulary => :environment do
    filename = 'stem_vocabulary_hash'
    raise Exception unless File.exist?(filename)
    text_class_vocabulary = Marshal.load( File.binread(filename) )
    text_class_vocabulary.each do |text_class_id, vocabulary|
      vocabulary.each do |token|
        ve = VocabularyEntry.find_or_create_by_token_and_state token, VocabularyEntry::ACCEPTED_STATE
        ve.text_class_ids = text_class_id
        ve.save!
      end
    end

    #Settings.bayes.regexp.downcased.each do |text_class_name, regexp|
    #  ve = VocabularyEntry.find_or_create_by_token_and_regexp_rule_and_state text_class_name, regexp, VocabularyEntry::ACCEPTED_STATE
    #  ve.text_classes << TextClass.find_by_name(text_class_name)
    #  ve.save!
    #end
    #VocabularyEntry.find_or_create_by_regexp_rule_and_state Settings.bayes.regexp.domain, VocabularyEntry::ACCEPTED_STATE
    #
    #Settings.bayes.regexp.truly_cities.each do |text_class_name, regexp|
    #  ve = VocabularyEntry.find_or_create_by_token_and_regexp_rule_and_state_and_truly_city text_class_name, regexp, VocabularyEntry::ACCEPTED_STATE, true
    #  ve.text_classes << TextClass.find_by_name(text_class_name)
    #  ve.save!
    #end

  end


  desc "Make outlier svm classifier"
  task :make_outlier_svm_classifier => :environment do
    svm = Svm.new
    VocabularyEntry.testing_mode = 1
    svm.make_training_and_test_files
    svm.train_model :need_scaling => true, :need_optimizing => true
    VocabularyEntry.testing_mode = nil
  end


  desc "Make ROSE-MNB one vs all classifiers"
  task :make_rose_mnb_classifiers => :environment do
    TextClass.all.each do |tc|
      Classifier.make_from_text_classes [tc], :name => "#{Classifier::ROSE_NAIVE_BAYES_NAME}-#{tc.eng_name}"
    end
  end
end