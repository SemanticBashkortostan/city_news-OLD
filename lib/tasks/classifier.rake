#coding: utf-8

namespace :classifier do
  desc "Set text_class to nil and add uncorrect_data tag into Feeds"
  task :filter_uncorrect_data => :environment do
    tcs = TextClass.where :name => ["Уфа", "Стерлитамак", "Нефтекамск", "Салават"]
    m_c = Classifier.create! :name => Classifier::NAIVE_BAYES_NAME
    m_c.text_classes = tcs.all
    Feed.where( :text_class_id => tcs ).all.each do |feed|
      if m_c.get_features_vector( feed.string_for_classifier ).empty?
        p [feed.id, feed.text_class.name, feed.string_for_classifier]
        feed.text_class = nil
        feed.mark_list << "uncorrect_data"
        feed.save!
      end
    end
    m_c.destroy


    tcs = TextClass.where :name => ["Стерлитамак", "Нефтекамск", "Салават", "Ишимбай"]
    m_c = Classifier.create! :name => Classifier::NAIVE_BAYES_NAME
    m_c.text_classes = tcs.all
    Feed.where( :text_class_id => tcs ).all.each do |feed|
      if m_c.get_features_vector( feed.string_for_classifier ).empty?
        p [feed.id, feed.text_class.name, feed.string_for_classifier]
        feed.text_class = nil
        feed.mark_list << "uncorrect_data"
        feed.save!
      end
    end
    m_c.destroy
  end

  task :naive_bayes_into_classifier_model => :environment do
    Classifier.destroy_all
    main_names = ["Уфа", "Стерлитамак", "Нефтекамск", "Салават"]
    main_classifier = Classifier.make_from_text_classes( TextClass.where(:name => main_names), :name => "#{Classifier::NAIVE_BAYES_NAME}-main" )
    p main_classifier.export_nb
    ishimbay_names = ["Стерлитамак", "Нефтекамск", "Салават", "Ишимбай"]
    ishimbay_classifier = Classifier.make_from_text_classes( TextClass.where(:name => ishimbay_names ), :name => "#{Classifier::NAIVE_BAYES_NAME}-ishimbay" )
  end


  desc "Print each classifier performance"
  task :performance => :environment do
    #ClassifiersEnsemble.test_all
    Classifier.all.each do |classifier|
      p "#{classifier.name} performance: "
      classifier.preload_classifier
      classifier.test( {:tags => Classifier::TRAIN_TAGS, :tags_options => {:exclude => true} }) #, :feeds_count => 3000 })
    end
  end
end
