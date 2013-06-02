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

module ClassifierPerformance
  TEST_TAGS  = ["dev_test"]

  # Test classifier by fetching feeds with specific tags
  # For test ROSE-MNB you must need use :feeds_count option
  # +options[:tags]+ - list of tags, like ["dev_test", "production"]
  # +options[:tags_options]+ - parameter which responses how to fetch, like {:match_all => true} or {:any => true}
  # +options[:feeds_count]+ - default fetch 20% from train_set_count feeds with specific tags
  # +options[:is_random]+ - if true then fetch feeds randomly
  # +options[:file_prefix]
  def test( options={} )
    # +:testing_options+ - test(options); +:data+ - array with [true or false, feed.id, feed.tc.name, tc.name, str];
    # +:uncorrect_data+ - data not accepted by filter [feed.id, feed.tc.name, str];
    # +:f_measures+ - hash {tc.name => f_measure}; +:accuracy+; +confusion_matrix+ - hash
    raise "You need pass at least :feeds_count for ROSE-MNB" if is_rose_naive_bayes? && !options[:feeds_count]
    @test_data = {:testing_options => options, :data => [], :uncorrect_data => []}
    test_feeds = get_testing_feeds( options[:tags], options[:tags_options], options[:feeds_count], options[:is_random] )
    confusion_matrix = build_confusion_matrix( test_feeds )
    classifier_performance confusion_matrix
    pretty_test_data_file( options[:file_prefix] )
  end


  # Return testing feeds which requires to special conditions as such as
  # +tags+, +tags_options+, +feeds_count+, +is_random+
  def get_testing_feeds( tags=nil, tags_options=nil, feeds_count = nil, is_random = false )
    tags ||= TEST_TAGS
    tags_options ||= {}
    feeds_count ||= ( train_set_count * 0.2 ).ceil
    testing_feeds = []
    text_classes.each_with_index do |tc, ind|
      if tc == Classifier::OTHER_TEXT_CLASS
        sub_tcs = TextClass.all - text_classes
        sub_tcs.each do |sub_tc|
          tmp_tags_options = tags_options.clone
          scope = Feed.where(:text_class_id => sub_tc).tagged_with( tags, tmp_tags_options )
          testing_feeds << ( (is_random == true ? scope.order("RANDOM()").limit(feeds_count/sub_tcs.count) : scope.order("id").limit(feeds_count/sub_tcs.count)) )
        end
      else
        tmp_tags_options = tags_options.clone
        scope = Feed.where(:text_class_id => tc).tagged_with( tags, tmp_tags_options )
        testing_feeds << ( (is_random == true ? scope.order("RANDOM()").limit(feeds_count) : scope.order("id").limit(feeds_count)) )
      end
    end
    testing_feeds.flatten!
    if is_rose_naive_bayes?
      testing_feeds.each{|feed| feed.text_class_id = Classifier::OTHER_TEXT_CLASS if feed.text_class_id != @class_id_for_rose}
    end
    return testing_feeds
  end


  def build_confusion_matrix( feeds )
     confusion_matrix = {}
     feeds.each do |feed|
       str = feed.string_for_classifier
       classified = classify( feed )
       unless classified
         @test_data[:uncorrect_data] << [feed.id, feed.text_class_id, str]
         next
       end
       klass_id = TextClass.find_by_id( classified[:class] ).try( :id ) || Classifier::OTHER_TEXT_CLASS
       @test_data[:data] << [feed.text_class_id == klass_id, feed.id, feed.text_class_id, klass_id, str, classified[:all_values][0]]
       confusion_matrix[feed.text_class_id] ||= {}
       confusion_matrix[feed.text_class_id][klass_id] = confusion_matrix[feed.text_class_id][klass_id].to_i + 1
     end
     return confusion_matrix
   end


   include Statistic
   # Adds classifier performance into @test_data hash
   def classifier_performance confusion_matrix
     accuracy = accuracy( confusion_matrix )
     @test_data[:confusion_matrix] = confusion_matrix
     @test_data[:accuracy] = accuracy
     @test_data[:f_measures] = {}
     text_classes.collect{|tc| tc.is_a?(TextClass) ? tc.id : tc}.each{ |klass_id| @test_data[:f_measures][klass_id] = f_measure(confusion_matrix, klass_id) }
   end


   def pretty_test_data_file file_prefix=nil
     # +:testing_options+ - test(options); +:data+ - array with [true or false, feed.id, feed.tc.name, tc.name, str];
     # +:uncorrect_data+ - data not accepted by filter [feed.id, feed.tc.name, str];
     # +:f_measures+ - hash {tc.name => f_measure}; +:accuracy+; +confusion_matrix+ - hash
     file = File.new("#{Rails.root}/log/#{file_prefix}classifiers_tests_#{name}.log", 'w')

     str = "#{Time.now} -- Classifier performance id:#{id} name:#{name} \n\n"

     str += "Test options: #{@test_data[:testing_options]} \n\n"

     str += "Accuracy: #{@test_data[:accuracy]} \n\n"

     str += "F-Measures: \n"
     @test_data[:f_measures].each{ |tc_name, f| str += "f-measure(#{tc_name})=#{f}\n" }
     str += "\n"

     str += "Confusion Matrix: \n"
     str += "#{@test_data[:confusion_matrix]}\n\n"

     str += "Uncorrect Data: \n"
     str += "feed.id\t feed.text_class_id\t feed.string_for_classifier\n"
     @test_data[:uncorrect_data].each do |row|
       str += "#{row[0]}\t #{row[1]}\t\t\t #{row[2]}\n"
     end
     str += "\n"

     str += "Data: \n"
     str += "Correct\t id\t feed.text_class\t classified_class\t str\t prob \n"
     @test_data[:data].sort_by{|data| (data[0] == false ? 0 : 1) }.each do |row|
       str += "#{row[0]}\t #{row[1]}\t #{row[2]}\t\t #{row[3]}\t\t\t #{row[4]}\t #{row[5]}\n"
     end
     str += "\n"

     file.write( str )
   end
end