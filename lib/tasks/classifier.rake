#coding: utf-8

namespace :classifier do
  desc "Migrate Naive Bayes classifier current state into Classifier model"
  task :naive_bayes_into_classifier_model => :environment do
    Classifier.destroy_all
    main_names = ["Уфа", "Стерлитамак", "Нефтекамск", "Салават"]
    main_classifier = Classifier.make_from_text_classes( TextClass.where(:name => main_names), :name => "#{Classifier::NAIVE_BAYES_NAME}-main" )
    ishimbay_names = ["Стерлитамак", "Нефтекамск", "Салават", "Ишимбай"]
    ishimbay_classifier = Classifier.make_from_text_classes( TextClass.where(:name => ishimbay_names ), :name => "#{Classifier::NAIVE_BAYES_NAME}-ishimbay" )
  end


  desc "Print each classifier performance"
  task :performance => :environment do
    Classifier.all.each do |classifier|
      p "#{classifier.name} performance: "
      classifier.preload_classifier
      classifier.test( {:tags => Classifier::TRAIN_TAGS, :tags_options => {:exclude => true}, :feeds_count => 3000, :is_random => true })
    end
  end
end
