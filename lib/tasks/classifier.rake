#coding: utf-8

namespace :classifier do
  desc "Set text_class to nil and add uncorrect_data tag into Feeds"
  task :filter_uncorrect_data => :environment do
    filter_uncorrect_data
  end


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
      classifier.test( {:tags => Classifier::TRAIN_TAGS, :tags_options => {:exclude => true} } ) #, :feeds_count => 3000 })
    end
  end


  desc "Classify fetched feeds"
  task :classify_fetched => :environment do
    classifiers_ensemble = ClassifiersEnsemble.new( Classifier.all, :preload => true )

    Feed.unclassified_fetched.each do |feed|
      classify_info = classifiers_ensemble.classify( feed.string_for_classifier )
      tag_list = ["classified"]
      if classify_info[:recommend_as_train] == true
        tag_list << "to_train"
      end
      feed.mark_list += tag_list
      feed.text_class = TextClass.find classify_info[:class]
      feed.save!
    end
  end


  desc "Train classifiers by fetched production feeds with tag to_train"
  task :train_by_production_data => :environment do
    train_by_production_data
  end


  def train_by_production_data
    Classifier.all.each do |classifier|
      classifier.preload_classifier
      fetched_trainers = Feed.fetched_trainers( 5, classifier.text_classes )
      next if fetched_trainers.nil?
      fetched_trainers.each do |train_feed|
        classifier.train( train_feed.string_for_classifier, train_feed.text_class )
      end
      classifier.save_to_database!
    end
  end


  def filter_uncorrect_data
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
end
