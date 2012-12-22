#coding: utf-8
namespace :bayes do


  def precision( confusion_matrix, klass )
    confusion_matrix[klass][klass] / confusion_matrix.values.inject(0.0){ |s,e| s += e[klass].to_f }
  end


  def recall(confusion_matrix, klass)
    confusion_matrix[klass][klass].to_f / confusion_matrix[klass].values.sum
  end


  def accuracy( confusion_matrix )
    val = 0.0
    denom = 0.0 # Count of all documents in test
    klasses = confusion_matrix.keys
    klasses.each do |klass|
      denom += confusion_matrix.values.inject(0.0){ |s,e| s += e[klass].to_f }
    end
    klasses.each do |klass|
      val += confusion_matrix[klass][klass] / denom
    end
    val
  end


  def f_measure(confusion_matrix, klass, beta=1)
    precision = precision(confusion_matrix, klass)
    recall = recall(confusion_matrix, klass)
    ( (beta**2 + 1) * precision * recall )/( beta**2 * precision + recall )
  end


  task :train_and_test => :environment do
    @nb = NaiveBayes::NaiveBayes.new
    cities = TextClass.where :name => ["Уфа", "Стерлитамак", "Салават"]
    @train_data = Feed.where( :mark_id => Feed::TRAINING, :text_class_id => cities  )
    @test_data  = Feed.where( :mark_id => Feed::DEV_TEST, :text_class_id => cities )

    @train_data.each do |feed|
      @nb.train( feed.title, feed.text_class_id )
      @nb.train( feed.summary, feed.text_class_id )
    end

    title_confusion_matrix = {}
    summary_confusion_matrix = {}
    @test_data.each do |feed|
      summary_classified = TextClass.find(@nb.classify( feed.summary )[:class]).name
      summary_confusion_matrix[feed.text_class.name] ||= {}
      summary_confusion_matrix[feed.text_class.name][summary_classified] = summary_confusion_matrix[feed.text_class.name][summary_classified].to_i + 1

      title_classified = TextClass.find(@nb.classify( feed.title )[:class]).name
      title_confusion_matrix[feed.text_class.name] ||= {}
      title_confusion_matrix[feed.text_class.name][title_classified] = title_confusion_matrix[feed.text_class.name][title_classified].to_i + 1
    end
    p ["summary", summary_confusion_matrix]
    p ["title", title_confusion_matrix]

  end


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
      classified = TextClass.find(@nb.classify( str )[:class]).name
      confusion_matrix[feed.text_class.name] ||= {}
      confusion_matrix[feed.text_class.name][classified] = confusion_matrix[feed.text_class.name][classified].to_i + 1
      p [feed.text_class.name, feed.title, feed.summary, feed.url, classified]
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