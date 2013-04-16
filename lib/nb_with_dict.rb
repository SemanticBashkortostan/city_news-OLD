#coding: utf-8

class NbWithDict

  include Statistic
  def initialize
    make_vocabulary
  end


  def make_vocabulary
    filename = 'big_vocabulary'
    if File.exist? filename
      @vocabulary = Marshal.load( File.binread(filename) ) 
    end
  end


  def run    
    ish_tc = TextClass.find_by_name "Стерлитамак"
    ufa_tcs = TextClass.where :name => ["Уфа", "Нефтекамск", "Ишимбай", "Салават"]
    text_classes = TextClass.where :id => [ish_tc] + ufa_tcs

    ish_td = Feed.tagged_with(["dev_train", "to_train"], :any => true).where( :text_class_id => ish_tc.id )
    ufa_td = Feed.tagged_with(["dev_train", "to_train"], :any => true).where( :text_class_id => ufa_tcs )
    
    ish_tdd = Feed.tagged_with("dev_test").where( :text_class_id => ish_tc.id ).all + Feed.tagged_with("was_trainer").where( :text_class_id => ish_tc.id ).all +
              Feed.tagged_with(["fetched", "production", "classified"], :match_all => true).where( :text_class_id => ish_tc ).all
    ufa_tdd = Feed.tagged_with("dev_test").where( :text_class_id => ufa_tcs ).all + Feed.tagged_with("was_trainer").where( :text_class_id => ufa_tcs ).all +
              Feed.tagged_with(["fetched", "production", "classified"], :match_all => true).where( :text_class_id => ufa_tcs ).all

    @nb = NaiveBayes::NaiveBayes.new 1.0, :rose, {:rose => {:duplicate_count => (ufa_td.count - ish_td.count).abs, :duplicate_klass => ish_tc.id} }  
    train_data = ish_td + ufa_td
    empty_feeds = {:train => [], :test => []}
    train_data.each_with_index do |feed, i|
      puts "Training #{i}/#{train_data.count}"
      features = filter( feed.features_for_text_classifier, true )
      if features.empty?
        empty_feeds[:train] << feed      
      else
        features << feed.domain
        feed.text_class_id = 100 if feed.text_class_id != ish_tc.id
        @nb.train( features, feed.text_class_id )
      end
    end

    confusion_matrix = {}
    test_data = ish_tdd + ufa_tdd
    test_data.each do |feed|
      features = filter( feed.features_for_text_classifier )
      if features.empty?
        empty_feeds[:test] << feed       
      else
        features << feed.domain
        classified = @nb.classify( features )[:class]
        feed.text_class_id = 100 if feed.text_class_id != ish_tc.id
        confusion_matrix[feed.text_class_id] ||= {}
        confusion_matrix[feed.text_class_id][classified] = confusion_matrix[feed.text_class_id][classified].to_i + 1
        p [ classified, feed.text_class_id, feed.id ]
      end
    end

    p "Ish train: #{ish_td.count}, #{ish_tdd.count}; Ufa train: #{ufa_td.count}, #{ufa_tdd.count}"
    p [empty_feeds[:train].count, empty_feeds[:test].count]
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

    # puts "Train: #{is_train}"
    # puts "Filtered #{filtered}"
    # puts "Uncorrect #{not_in_voc}"
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


# Ufa and ishimbay ROSE
# {1=>{1=>13, 4=>1}, 4=>{4=>13}}
# 0.9629629629629629
#  => 0.9629629629629629 

# Ufa and ishimbay standard MNB
# {1=>{1=>13, 4=>1}, 4=>{4=>13}}
# 0.9629629629629629
#  => 0.9629629629629629 


# without ROSE
# {2=>{2=>69, 100=>16}, 100=>{100=>795, 2=>3}}
# 0.9784824462061155
#  => 0.9784824462061155 

# WITH ROSE
# "Ish train: 221, 94; Ufa train: 2704, 840"
# [77, 51]
# {2=>{2=>68, 100=>17}, 100=>{100=>795, 2=>3}}
# 0.9773499433748585
#  => 0.9773499433748585 


# Ишимбай vs ALL
#
# With ROSE
# "Ish train: 62, 41; Ufa train: 2925, 934"
# [82, 54]
# {1=>{1=>32, 100=>6}, 100=>{100=>881, 1=>2}}
# 0.991313789359392
#  => 0.991313789359392 
#
# Without ROSE
# "Ish train: 62, 41; Ufa train: 2925, 934"
# [82, 54]
# {1=>{1=>28, 100=>10}, 100=>{100=>881, 1=>2}}
# 0.9869706840390879
#  => 0.9869706840390879 


# Уфа vs ALL
#
# WITHOUT ROSE
# "Ish train: 2031, 635; Ufa train: 956, 340"
# [82, 54]
# {4=>{4=>582, 100=>25}, 100=>{100=>290, 4=>24}}
# 0.9467969598262758
#  => 0.9467969598262758 
#
# Уфа vs ALL with ROSE
# "Ish train: 2031, 635; Ufa train: 956, 340"
# [82, 54]
# {4=>{4=>588, 100=>19}, 100=>{100=>289, 4=>25}}
# 0.9522258414766558
#  => 0.9522258414766558 


# Стерлитамак вс АЛЛ
# WITHOUT ROSE
# "Ish train: 429, 112; Ufa train: 2558, 863"
# [82, 54]
# {3=>{3=>93, 100=>9}, 100=>{100=>789, 3=>30}}
# 0.9576547231270359
#  => 0.9576547231270359 
# WITH ROSE
# "Ish train: 429, 112; Ufa train: 2558, 863"
# [82, 54]
# {3=>{3=>91, 100=>11}, 100=>{100=>801, 3=>18}}
# 0.968512486427796
#  => 0.968512486427796 
