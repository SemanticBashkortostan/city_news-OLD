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
    text_classes = TextClass.where :name => (TextClass.pluck(:name) - ["Ишимбай"])
    train_data = Feed.tagged_with(["dev_train", "to_train"], :any => true).where( :text_class_id => text_classes ).all.shuffle

    test_data = Feed.tagged_with("dev_test").where( :text_class_id => text_classes ).all + 
                Feed.tagged_with("was_trainer", :match_all => true).where(:text_class_id => text_classes).all
    test_data.uniq!

    empty_feeds = {:train => [], :test => []}
    train_data.each_with_index do |feed, i|
      puts "Training #{i}/#{train_data.count}"
      features = filter( feed.features_for_text_classifier, true )
      if features.empty?
        empty_feeds[:train] << feed      
      else
        features << feed.domain
        @nb.train( features, feed.text_class_id )
      end
    end

    confusion_matrix = {}
    test_data.each do |feed|
      features = filter( feed.features_for_text_classifier )
      if features.empty?
        empty_feeds[:test] << feed       
      else
        features << feed.domain
        classified = @nb.classify( features )[:class]
        confusion_matrix[feed.text_class_id] ||= {}
        confusion_matrix[feed.text_class_id][classified] = confusion_matrix[feed.text_class_id][classified].to_i + 1
        p [ classified, feed.text_class_id, feed.id ]
      end
    end

    p [empty_feeds[:train].count, empty_feeds[:test].count]
    p empty_feeds[:test]
    p confusion_matrix
    p accuracy(confusion_matrix)
  end


  def filter features, is_train=false
    return [] if features.nil? 

    filtered = []    
    not_in_voc = []    
    features.each do |f|      
      if f.is_a?(Array)
        filtered += f 
      elsif @vocabulary.include?( f )
        filtered << f 
      else
        not_in_voc << f
      end
    end         

    puts "Train: #{is_train}"
    puts "Filtered #{filtered}"
    puts "Uncorrect #{not_in_voc}"
    #gets

    filtered
  end

end
# Without domain
# {4=>{4=>13}, 3=>{3=>13}, 5=>{5=>14}, 1=>{1=>12, 3=>1, 2=>1}, 2=>{2=>10, 4=>2}}
# 0.9393939393939393

# With domain
# [87, 3]
# {4=>{4=>12, 3=>1}, 3=>{3=>13}, 5=>{5=>14}, 1=>{1=>13, 3=>1}, 2=>{2=>12}}
# 0.9696969696969697
#  => 0.9696969696969697 


# With other test feeds with domain
# {4=>{4=>566, 3=>22, 5=>1}, 3=>{3=>75, 4=>9, 2=>1}, 5=>{5=>45, 3=>2, 4=>24}, 1=>{1=>14, 3=>3, 4=>6}, 2=>{2=>50, 3=>5, 4=>13}}
# 0.8971291866028709


# Without Ufa and Ishimbay
# {3=>{3=>13}, 5=>{5=>14}, 2=>{2=>12}}
# 1.0
