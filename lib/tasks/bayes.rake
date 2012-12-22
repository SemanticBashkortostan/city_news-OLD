#coding: utf-8
namespace :bayes do


  require 'statistic'

  include Statistic


  task :train_and_test_with_merging => :environment do
    @nb = NaiveBayes::NaiveBayes.new
    cities_names = ["Уфа", "Стерлитамак", "Салават"]
    cities = TextClass.where :name => cities_names
    @train_data = Feed.where( :mark_id => Feed::TRAINING, :text_class_id => cities  )
    @test_data  = Feed.where( :mark_id => Feed::DEV_TEST, :text_class_id => cities )

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
    p @nb.export[:vocabolary].sort
  end


  task :test_with_regexp => :environment do
    cities_names = ["Уфа", "Стерлитамак", "Салават"]
    cities = TextClass.where :name => cities_names
    @test_data  = Feed.where( :mark_id => [Feed::DEV_TEST], :text_class_id => cities )

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
    regexp_salavat = /(Салав+[[:word:]]+|САЛАВ+[[:word:]]+|салав+[[:word:]]+)/
    regexp_ufa = /(Уф+[[:word:]]+|УФ+[[:word:]]+|уфи+[[:word:]]+)/
    regexp_str = /(Стерл+[[:word:]]+|СТЕРЛ+[[:word:]]+|стерл+[[:word:]]+)/
    return "Стерлитамак" if not string.scan(regexp_str).blank?
    return "Салават" if not string.scan(regexp_salavat).blank?
    return "Уфа" if not string.scan(regexp_ufa).blank?
  end


end