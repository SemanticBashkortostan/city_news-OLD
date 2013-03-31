#coding: utf-8

class ReBayesTest
  include Statistic

  attr_accessor :positive_set, :negative_set, :nb
  def initialize

    positive_filename = "positive_re_set"
    negative_filename = "negative_re_set"
    @positive_set = load_set positive_filename
    @negative_set = load_set negative_filename   
    make_train_and_test_sets

    @nb = NaiveBayes::NaiveBayes.new 
  end


  def train
    @positive_set.each do |example|
      fv = make_feature_vector(example)  
      @nb.train(fv, 1)
    end

    @negative_set.each do |example|
      fv = make_feature_vector(example)  
      @nb.train(fv, -1)
    end
  end


  def test
    confusion_matrix = { 1 => {}, -1 => {} }

    @test_positive_set.each do |example|
      fv = make_feature_vector(example) 
      classified = @nb.classify(fv)
      p [1, classified[:class]]
      confusion_matrix[1][classified[:class]] = confusion_matrix[1][classified[:class]].to_i + 1
    end

    @test_negative_set.each do |example|
      fv = make_feature_vector(example) 
      classified = @nb.classify(fv)
      p [-1, classified[:class]]
      confusion_matrix[-1][classified[:class]] = confusion_matrix[-1][classified[:class]].to_i + 1
    end
    p confusion_matrix

    p ["f-measure", 1, f_measure( confusion_matrix, 1 )]
    p ["f-measure", -1, f_measure( confusion_matrix, -1 )]

    p ["precision, recall", 1, precision(confusion_matrix, 1), recall(confusion_matrix, 1)]
    p ["precision, recall", -1, precision(confusion_matrix, -1), recall(confusion_matrix, -1)]

    p ["accuracy", accuracy(confusion_matrix)]
  end


  def make_feature_vector example
    # without :distance 
    ending_keys = [:tc_token, :tc_right_context, :tc_left_context, :ne_token, :ne_right_context, :ne_left_context]
    feature_keys = [           
                          :text_class_id, :tc_is_first_token, :tc_token,
                          :tc_right_context, :tc_left_context, :tc_quoted,
                          :has_other_cities, :in_one_sent, :tc_word_position,
                          :tc_same_as_feed,
                          :ne_is_first_token, :ne_token, :ne_right_context, 
                          :ne_left_context, :ne_quoted
                    ]
    feature_vector = []    
    feature_keys.each do |key|
      if example[key] && ending_keys.include?(key)
        if example[key].length > 3
          example_val = example[key][-3..-1]
        else
          example_val = example[key][-1]
        end
      else
        example_val = example[key]
      end

      val = "#{key}_#{example_val}"
      feature_vector << val 
    end
    return feature_vector
  end


  def self.run
    rbt = ReBayesTest.new
    rbt.train
    rbt.test
  end



  protected



  def make_train_and_test_sets
    @test_positive_set = @positive_set.sample(100)
    @positive_set = @positive_set - @test_positive_set
    @test_negative_set = @negative_set.sample(100)
    @negative_set = (@negative_set - @test_negative_set)[0...@positive_set.count]
  end


  def load_set filename
    loaded_hash = Marshal.load(File.binread(filename))     
    return loaded_hash.values.to_a.flatten if loaded_hash.is_a?( Hash )
    return loaded_hash.flatten
  end
end