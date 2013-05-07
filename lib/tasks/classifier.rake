#coding: utf-8

namespace :classifier do
  desc "Set text_class to nil and add uncorrect_data tag into Feeds"
  task :filter_uncorrect_data => :environment do
    #filter_uncorrect_data
    # 1176 / 5594. But what will be after custom DIPRE? and what accuracy
    filter_empty_features_vector_for_rose_mnb
  end


  task :naive_bayes_into_classifier_model => :environment do
    Classifier.destroy_all
    all_names = ["Уфа", "Стерлитамак", "Нефтекамск", "Салават", "Ишимбай"]
    all_classifier = Classifier.make_from_text_classes( TextClass.where(:name => all_names ), :name => "#{Classifier::NAIVE_BAYES_NAME}-all" )
    TextClass.where( :name => all_names ).all.each do |tc|
      FeedSource.all.each do |fc|
        str = "#{tc.name} Domain: #{fc.url}"
        all_classifier.train(str, tc)
      end
    end
    all_classifier.save_to_database!

    #
    #main_names = ["Уфа", "Стерлитамак", "Нефтекамск", "Салават"]
    #main_classifier = Classifier.make_from_text_classes( TextClass.where(:name => main_names), :name => "#{Classifier::NAIVE_BAYES_NAME}-main" )
    #ishimbay_names = ["Стерлитамак", "Нефтекамск", "Салават", "Ишимбай"]
    #ishimbay_classifier = Classifier.make_from_text_classes( TextClass.where(:name => ishimbay_names ), :name => "#{Classifier::NAIVE_BAYES_NAME}-ishimbay" )
    #
    #TextClass.where( :name => main_names ).all.each do |tc|
    #  FeedSource.all.each do |fc|
    #    str = "#{tc.name} Domain: #{fc.url}"
    #    main_classifier.train(str, tc)
    #  end
    #end
    #p main_classifier.export_nb
    #
    #TextClass.where( :name => ishimbay_names ).all.each do |tc|
    #  FeedSource.all.each do |fc|
    #    str = "#{tc.name} Domain: #{fc.url}"
    #    ishimbay_classifier.train(str, tc)
    #  end
    #end
    #
    #main_classifier.save_to_database!
    #ishimbay_classifier.save_to_database!
    #
    #main_classifier.reload
    #main_classifier.preload_classifier
  end


  desc "Write each classifier performance in .log. Also prints all classifiers compare in .csv."
  task :performance => :environment do
    Classifier.all.each do |classifier|
      p "#{classifier.name} performance: "
      classifier.preload_classifier
      classifier.test( {:tags => Classifier::TRAIN_TAGS + Classifier::UNCORRECT_DATA_TAGS, :tags_options => {:exclude => true} , :feeds_count => 150, :file_prefix => '150filtered_trained_domain_'} )
    end
    ClassifiersEnsemble.test_all :name => '150filtered_trained_domain', :count => 150
  end


  desc "Classify fetched feeds"
  task :classify_fetched => :environment do
    Scheduler::Classifier.classify_fetched
  end


  desc "Train classifiers by fetched production feeds with tag to_train"
  task :train_by_production_data => :environment do
    Scheduler::Classifier.train_by_production_data
  end


  # "829 / 5594" - Filtered :testing => true
  # "2085 / 5594" - default state
  def filter_empty_features_vector_for_rose_mnb
    train_feeds = Feed.tagged_with( Classifier::TRAIN_TAGS, :any => true )
    empty_features_feeds = []
    train_feeds.each_with_index do |feed, ind|
      puts "Processed #{ind}/#{train_feeds.count}. Empty: #{empty_features_feeds.count}"
      empty_features_feeds << feed if feed.features_for_text_classifier().empty?
    end
    p "#{empty_features_feeds.count} / #{train_feeds.count}"
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
