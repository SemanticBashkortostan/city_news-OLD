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

    @test_data.each do |feed|
      p [ feed.title, feed.text_class.name, TextClass.find(@nb.classify( feed.summary )[:class]).name, TextClass.find(@nb.classify( feed.title )[:class]).name ]
    end
    p @nb.export

  end
end