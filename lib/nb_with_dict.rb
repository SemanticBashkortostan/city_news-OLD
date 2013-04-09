#coding: utf-8

class NbWihDict
  def initialize
    @nb = NaiveBayes::NaiveBayes.new  
  end


  def make_vocabolary
    filename = 'lemma_vocabolary_hash'
    if File.exist? filename
      @vocabolary = Marshal.load (File.binread(filename))
      @all_vocabolary = @vocabolary.values.collect{|hash| hash.keys}.flatten.uniq    
    else    
  end


  def run
    pos_train_data = Feed.tagged_with(["dev_train", "to_train", "was_trainer"], :any => true).where( :text_class_id => pos_tc  )
    neg_train_data  = Feed.tagged_with(["dev_train", "to_train", "was_trainer"], :any => true).where( 
                                        :text_class_id => (cities - [pos_tc])  
                                        ).all[0..(pos_train_data.count*0.3).ceil] + outlier_data[0...outlier_data.count/2]
    train_data = pos_train_data + neg_train_data

    test_data  = Feed.tagged_with("dev_test").where( :text_class_id => cities ).all + outlier_data[outlier_data.count/2...outlier_data.count]

  end



end