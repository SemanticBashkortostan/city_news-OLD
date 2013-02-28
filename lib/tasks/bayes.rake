#coding: utf-8
namespace :bayes do


  require 'statistic'

  include Statistic


  desc 'Train bayes network with training data'
  task :init_train => :environment do
    @nb = NaiveBayes::NaiveBayes.new
    text_classes = TextClass.where :name => Settings.bayes.klasses
    train_data = Feed.tagged_with("dev_train").where( :text_class_id => text_classes  )

    train_data.each do |feed|
      @nb.train feed.string_for_classifier, feed.text_class_id
    end

    @nb.save_to_database
  end


  task :train_and_test_with_merging => :environment do
    @nb = NaiveBayes::NaiveBayes.new
    cities_names = Settings.bayes.klasses
    cities = TextClass.where :name => cities_names
    @train_data = Feed.tagged_with("dev_train").where( :text_class_id => cities )
    @test_data  = Feed.tagged_with("dev_test").where( :text_class_id => cities )

    @train_data.each do |feed|
      str = feed.string_for_classifier
      @nb.train( str, feed.text_class_id )
    end

    confusion_matrix = {}
    @test_data.each do |feed|
      str = feed.string_for_classifier
      nb_classfied = @nb.classify( str )
      classified = TextClass.find(nb_classfied[:class]).name
      confusion_matrix[feed.text_class.name] ||= {}
      confusion_matrix[feed.text_class.name][classified] = confusion_matrix[feed.text_class.name][classified].to_i + 1
      p [feed.text_class.name, feed.title, feed.summary, classified, nb_classfied[:value]] if feed.text_class.name == "Уфа"
    end
    accuracy = accuracy( confusion_matrix )
    p confusion_matrix
    p accuracy
    cities_names.each{ |city| p [city, f_measure(confusion_matrix, city)] }
    p @nb.export
  end



  task :classify_fetched => :environment do
    @nb = NaiveBayes::NaiveBayes.new
    nb_data = TextClassFeature.import_to_naive_bayes
    @nb.import!( nb_data[:docs_count], nb_data[:words_count], nb_data[:vocabolary]  )
    feeds = Feed.tagged_with(["fetched", "production"]).where(:text_class_id => nil)
    multiplicator = 42
    feeds.each do |feed|
      nb_classified = @nb.classify( feed.string_for_classifier )
      tag_list = ["classified"]

      BayesLogger.bayes_logger.info ["bayes probabilities", nb_classified[:all_values], ["klass_id", nb_classified[:class]], feed.id]
      if nb_classified[:all_values][0] > (nb_classified[:all_values][1] * multiplicator)
        tag_list << "to_train"
      end
      feed.mark_list += tag_list
      feed.text_class = TextClass.find nb_classified[:class]
      feed.save!
    end
  end


  task :train_by_production_data => :environment do
    train_by_production_data  
  end


  def train_by_production_data
    return nil if Feed.fetched_trainers.nil?
    @nb = NaiveBayes::NaiveBayes.new
    nb_data = TextClassFeature.import_to_naive_bayes
    @nb.import!( nb_data[:docs_count], nb_data[:words_count], nb_data[:vocabolary]  )

    Feed.fetched_trainers.each do |feed|
      @nb.train( feed.string_for_classifier, feed.text_class_id )
      feed.mark_list.delete("to_train")
      feed.mark_list << "was_trainer"
      feed.save
    end

    @nb.save_to_database  
  end






  #--------------------------------
  #-------To Delete Section--------
  #--------------------------------

  task :test_with_regexp => :environment do
    cities_names = Settings.bayes.klasses
    cities = TextClass.where :name => cities_names
    @test_data  = Feed.tagged_with("dev_test").where( :text_class_id => cities )

    confusion_matrix = {}
    @test_data.each do |feed|
      classified = classify_with_regexp( feed.summary + feed.title )
      confusion_matrix[feed.text_class.name] ||= {}
      confusion_matrix[feed.text_class.name][classified] = confusion_matrix[feed.text_class.name][classified].to_i + 1
    end
    p confusion_matrix
    p accuracy(confusion_matrix)

  end


  def classify_with_regexp( string )
    Settings.bayes.klasses.each do |klass_name|
      return klass_name unless string.scan( Regexp.new( Settings.bayes.regexp[klass_name] ) ).blank?
    end
  end


end