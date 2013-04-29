# Classifier's wrapper which runs in clock daemon by schedule
class Scheduler::Classifier
  def self.classify_fetched
    ensbm_rose_mnb_classifiers = Classifier.where("name like '#{Classifier::ROSE_NAIVE_BAYES_NAME}%'").all.collect do |cl|
      ClassifiersEnsemble.new( [cl], :preload => true, :multiplicator => 1000 )
    end

    raise "Ensemble is blank!" if ensbm_rose_mnb_classifiers.blank?

    Feed.unclassified_fetched.all.each do |feed|
      ensbm_rose_mnb_classifiers.each do |classifier_ensb|
        classify_info = classifier_ensb.classify( feed )
        tag_list = ["classified"]
        if classify_info[:recommend_as_train] == true
          tag_list << "to_train"
        end
        feed.mark_list += tag_list
        feed.classified_infos.build :classifier_id => classifier_ensb.classifier_id, :text_class_id => TextClass.find_by_id( classify_info[:class] ).try(:id),
                                    :to_train => classify_info[:recommend_as_train], :score => classify_info[:score]
      end
      feed.text_class_id = feed.classified_infos.max_by(&:score).text_class_id
      feed.save!
    end

    Feed.tagged_with("new_unsatisfaction", :match_all => true).all.each do |feed|
      ensbm_rose_mnb_classifiers.each do |classifier_ensb|
        classify_info = classifier_ensb.classify( feed )
        tag_list = ["classified"]
        feed.mark_list += tag_list
        feed.classified_infos.build :classifier_id => classifier_ensb.classifier_id, :text_class_id => TextClass.find_by_id( classify_info[:class] ).try(:id),
                                    :score => classify_info[:score]
      end
      feed.text_class_id = feed.classified_infos.with_text_class.max_by(&:score).text_class_id
      feed.save!
    end
  end


  #TODO: Train by production data for ROSE
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
