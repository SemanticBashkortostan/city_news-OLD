#coding: utf-8

class NbWithDict

  include Statistic
  attr_accessor :all_vocabolary_hash
  def initialize
    @nb = NaiveBayes::NaiveBayes.new  
    make_vocabolary
  end


  def make_vocabolary
    filename = 'lemma_vocabolary_hash'
    if File.exist? filename
      @vocabolary = Marshal.load (File.binread(filename))
      @all_vocabolary = @vocabolary.values.collect{|hash| hash.values.collect{|e| e[:lemma] } }.flatten.uniq  
      big_hash = {}
      @all_vocabolary_hash = @vocabolary.values.each{ |v| big_hash.merge!(v) }
      @all_vocabolary_hash = big_hash
    end
  end


  def run    
    text_classes = TextClass.all
    train_data = Feed.tagged_with(["dev_train", "to_train", "was_trainer"], :any => true).where( :text_class_id => text_classes ).all.shuffle
    test_data = Feed.tagged_with("dev_test").where( :text_class_id => text_classes ).all + train_data[0...100]
    train_data = train_data[100..-1]

    train_data.each_with_index do |feed, i|
      puts "Training #{i}/#{train_data.count}"
      features = filter( feed.features_for_text_classifier, true )
      if features.empty?
        puts features 
        puts feed.string_for_classifier
        gets
      else
        @nb.train( features, feed.text_class_id )
      end
    end

    confusion_matrix = {}
    test_data.each do |feed|
      features = filter( feed.features_for_text_classifier )
      classified = @nb.classify( features )[:class]
      confusion_matrix[feed.text_class_id] ||= {}
      confusion_matrix[feed.text_class_id][classified] = confusion_matrix[feed.text_class_id][classified].to_i + 1
      puts [ classified, feed.text_class_id ]
    end
    p confusion_matrix
    p accuracy(confusion_matrix)
  end


  def filter features, is_train=false
    return features
    filtered = []
    features.each do |f|      
      filtered << f if @all_vocabolary.include?( f ) || f.mb_chars.downcase.to_s == f
    end      
    filtered
  end

end