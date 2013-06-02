#
# CityNews - news aggregator software
# Copyright (C) 2013  Idris Yusupov
#
# This file is part of CityNews.
#
# CityNews is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# CityNews is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with CityNews.  If not, see <http://www.gnu.org/licenses/>.
#
#coding: utf-8

class NbWithDict

  include Statistic
  def initialize
    #make_vocabulary
  end


  def make_vocabulary
    filename = 'big_vocabulary'
    if File.exist? filename
      @vocabulary = Marshal.load( File.binread(filename) ) 
    end
  end


  def run
    svm = OutlierSvm.new "outlier_classifier-new/outlier_city_svm", :from_cache => true
    @max_test_data_count = 1000

    cities_train_data, cities_test_data = svm.get_train_and_test_feeds(:city)
    cities_train_data = cities_train_data.find_all{|e| e.features_for_text_classifier.present?}

    test_data_count = cities_test_data.count
    test_data_count = @max_test_data_count if test_data_count > @max_test_data_count

    cities_test_data = cities_test_data.shuffle[0...test_data_count]

    outlier_data = svm.get_train_and_test_feeds( :outlier )
    outlier_test_data = outlier_data[0...test_data_count]
    outlier_train_data = outlier_data[test_data_count...outlier_data.count].find_all{|e| e.features_for_text_classifier.present?}

    @nb = NaiveBayes::NaiveBayes.new 1.0, :rose, {:rose => {:duplicate_count => (outlier_train_data.count - cities_train_data.count).abs, :duplicate_klass => -1} }
    train_data = outlier_train_data + cities_train_data
    empty_feeds = {:train => [], :test => []}

    train_data.each_with_index do |feed, i|
      puts "Training #{i}/#{train_data.count}"
      features = feed.features_for_text_classifier
      if features.empty?
        empty_feeds[:train] << feed
      else
        klass = get_klass(feed.text_class.try(:id))
        @nb.train( features, klass )
      end
    end

    #confusion_matrix, uncorrects = test_nb(cities_test_data, empty_feeds, outlier_test_data)
    feeds = Feed.where('created_at > ?', 1.hour.ago).all
    feeds.each_with_index do |feed, i|
      puts "Processed #{i}/#{feeds.count}"
      features = feed.features_for_text_classifier
      if features.blank?
        empty_feeds[:test] << feed
      else
        classified = @nb.classify( features )[:class]
        if classified == 1
          feed.mark_list << "nb_outlier"
          feed.save!
        end
      end

    end

    #p "City: #{cities_train_data.count}, #{cities_test_data.count}; Outlier: #{outlier_train_data.count}, #{outlier_test_data.count}"
    #p [empty_feeds[:train].count, empty_feeds[:test].count]
    ##p confusion_matrix
    ##p accuracy(confusion_matrix)
    #return uncorrects
  end


  def test_nb(cities_test_data, empty_feeds, outlier_test_data)
    confusion_matrix = {}
    uncorrects = []
    test_data = cities_test_data + outlier_test_data
    test_data.each_with_index do |feed, i|
      puts "Testing #{i}/#{test_data.count}"
      features = feed.features_for_text_classifier
      if features.empty?
        empty_feeds[:test] << feed
      else
        classified = @nb.classify(features)[:class]
        klass = get_klass(feed.text_class.try(:id))
        confusion_matrix[klass] ||= {}
        confusion_matrix[klass][classified] = confusion_matrix[klass][classified].to_i + 1
        if classified != klass
          uncorrects << [classified, klass, feed]
        end
      end
    end
    return confusion_matrix, uncorrects
  end


  def get_klass( text_class_id )
    text_class_id.nil? ? klass = 1 : klass = -1
  end


  def run_tmp
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