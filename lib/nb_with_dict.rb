#coding: utf-8

class NbWithDict

  include Statistic
  def initialize
    @nb = NaiveBayes::NaiveBayes.new  
    make_vocabulary
  end


  def make_vocabulary
    filename = 'big_vocabulary'
    if File.exist? filename
      @vocabulary = Marshal.load( File.binread(filename) ) 
    end
  end


  def run    
    text_classes = TextClass.all
    train_data = Feed.tagged_with(["dev_train", "to_train", "was_trainer"], :any => true).where( :text_class_id => text_classes ).all.shuffle

    test_data = Feed.tagged_with("dev_test").where( :text_class_id => text_classes ).all + Feed.tagged_with(%w(fetched production classified), :match_all => true).all
    test_data.uniq!

    empty_features_count = 0
    train_data.each_with_index do |feed, i|
      puts "Training #{i}/#{train_data.count}"
      features = filter( feed.features_for_text_classifier, true )
      if features.empty?
        empty_features_count += 1        
      else
        @nb.train( features, feed.text_class_id )
      end
    end

    p "train empty_features_count - #{empty_features_count} / #{train_data.count}"
    gets

    empty_features_count = 0
    confusion_matrix = {}
    test_data.each do |feed|
      features = filter( feed.features_for_text_classifier )
      if features.empty?
        empty_features_count += 1        
      else
        classified = @nb.classify( features )[:class]
        confusion_matrix[feed.text_class_id] ||= {}
        confusion_matrix[feed.text_class_id][classified] = confusion_matrix[feed.text_class_id][classified].to_i + 1
        puts [ classified, feed.text_class_id ]
      end
    end
    p "test empty_features_count - #{empty_features_count} / #{test_data.count}"
    gets
    p confusion_matrix
    p accuracy(confusion_matrix)
  end


  def filter features, is_train=false
    filtered = []
    return filtered if features.blank?
    features.each do |f|      
      filtered << f if @vocabulary.include?( f )
    end      
    filtered
  end

end