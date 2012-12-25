#coding: utf-8
namespace :bayes do


  require 'statistic'

  include Statistic


  desc 'Train bayes network with training data'
  task :init_train => :environment do
    nb = NaiveBayes::NaiveBayes.new
    text_classes = TextClass.where :name => Settings.bayes.klasses
    train_data = Feed.tagged_with("train").where( :text_class_id => cities  )

    train_data.each do |feed|
      @nb.train feed.training_string, feed.text_class_id
    end

    @nb.save_to_database
  end


  task :train_and_test_with_merging => :environment do
    @nb = NaiveBayes::NaiveBayes.new
    cities_names = Settings.bayes.klasses
    cities = TextClass.where :name => cities_names
    @train_data = Feed.tagged_with("train").where( :text_class_id => cities  )
    @test_data  = Feed.tagged_with("dev_test").where( :text_class_id => cities )

    @train_data.each do |feed|
      str = feed.title + " " + feed.summary + " " + "Domain: #{feed.url}"
      @nb.train( str, feed.text_class_id )
    end

    confusion_matrix = {}
    @test_data.each do |feed|
      str = feed.title + " " + feed.summary + " " + "Domain: #{feed.url}"
      nb_classfied = @nb.classify( str )
      classified = TextClass.find(nb_classfied[:class]).name
      confusion_matrix[feed.text_class.name] ||= {}
      confusion_matrix[feed.text_class.name][classified] = confusion_matrix[feed.text_class.name][classified].to_i + 1
      p [feed.text_class.name, feed.title, classified, nb_classfied[:value]]
    end
    accuracy = accuracy( confusion_matrix )
    p confusion_matrix
    p accuracy
    cities_names.each{ |city| p [city, f_measure(confusion_matrix, city)] }
    p @nb.export
  end


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
    Settings.bayes.shorten_klasses.each do |short_name|
      regexp_arr = Settings.bayes.regexp["short_name"]
      return regexp_arr[1] unless string.scan( Regexp.new( regexp_arr[0] ) ).blank?
    end
  end


end