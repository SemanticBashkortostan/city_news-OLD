class Scheduler::Classifier
  def self.classify_fetched
    ensbm_rose_mnb_classifiers = Classifier.where("name like '#{Classifier::ROSE_NAIVE_BAYES_NAME}%'").all.collect do |cl|
      ClassifiersEnsemble.new( [cl], :preload => true )  
    end
    Feed.unclassified_fetched.each do |feed|
      ensbm_rose_mnb_classifiers.each do |classifier|
        classify_info = classifiers_ensemble.classify( feed )
        #TODO: Make it to work for several classes. 
        #So we may have to_train for several_classes and simply several text_classes. ? has_many :through ?
        tag_list = ["classified"]
        if classify_info[:recommend_as_train] == true
          tag_list << "to_train"
        end
        feed.mark_list += tag_list
        feed.text_class = TextClass.find classify_info[:class]
        feed.save
      end
    end
  end


  def self.train_by_production_data
    ::Classifier.all.each do |classifier|
      classifier.preload_classifier
      fetched_trainers = Feed.fetched_trainers( 5, classifier.text_classes, classifier.id )
      next if fetched_trainers.nil?
      fetched_trainers.each do |train_feed|
        classifier.train( train_feed.string_for_classifier, train_feed.text_class )
        classifier.train_feeds << train_feed
      end
      classifier.save_to_database!
    end
  end

  def self.classify_by_mnb
    classifiers_ensemble = ClassifiersEnsemble.new( [Classifier.find_by_name("#{Classifier::NAIVE_BAYES_NAME}-all")], :preload => true )

    Feed.unclassified_fetched.each do |feed|
      classify_info = classifiers_ensemble.classify( feed.string_for_classifier )
      tag_list = ["classified"]
      if classify_info[:recommend_as_train] == true
        tag_list << "to_train"
      end
      feed.mark_list += tag_list
      feed.text_class = TextClass.find classify_info[:class]
      feed.save
    end
  end

end
