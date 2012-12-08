#coding: utf-8
namespace :bayes do
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
    cities = TextClass.where :name => ["Уфа", "Стерлитамак", "Салават"]
    @train_data = Feed.where( :mark_id => Feed::TRAINING, :text_class_id => cities  )
    @test_data  = Feed.where( :mark_id => Feed::DEV_TEST, :text_class_id => cities )

    @train_data.each do |feed|
      @nb.train( feed.title + " " + feed.summary, feed.text_class_id )
    end

    confusion_matrix = {}
    @test_data.each do |feed|
      classified = TextClass.find(@nb.classify( feed.title + " " + feed.summary )[:class]).name
      confusion_matrix[feed.text_class.name] ||= {}
      confusion_matrix[feed.text_class.name][classified] = confusion_matrix[feed.text_class.name][classified].to_i + 1
    end
    p confusion_matrix
  end
end