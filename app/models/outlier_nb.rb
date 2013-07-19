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
class OutlierNb
  include FeedsHelper
  include Statistic

  CITY = -1
  OUTLIER = 1

  attr_reader :filename
  def initialize filename="outlier-rose-nb"
    @max_test_data_count = 1000

    @filename =  "#{Rails.root}/project_files/classifiers/#{filename}"
    path = @filename.split("/")[0...-1].join("/")
    FileUtils.mkdir_p(path) unless File.exists?(path)
  end


  def make_classifier
    test_data_count = @max_test_data_count
    cities_train_data, cities_test_data = FeedsHelper.get_train_and_test_feeds(:city, true)
    cities_train_data = cities_train_data.find_all{|e| e.features_for_text_classifier.present?}

    cities_test_data = cities_test_data.shuffle[0...test_data_count]

    outlier_data = FeedsHelper.get_train_and_test_feeds( :outlier, true )
    outlier_test_data = outlier_data[0...test_data_count]
    outlier_train_data = outlier_data[test_data_count...outlier_data.count].find_all{|e| e.features_for_text_classifier.present?}

    @nb = NaiveBayes::NaiveBayes.new 1.0, :rose, {:rose => {:duplicate_count => (outlier_train_data.count - cities_train_data.count).abs, :duplicate_klass => CITY} }

    train_data = outlier_train_data + cities_train_data
    train_data.each_with_index do |feed, i|
      puts "Training #{i}/#{train_data.count}"
      train( feed )
    end
    save
  end


  def train feed
    features = feed.features_for_text_classifier
    if features.empty?
      p ["Exception in OutlierNb", features, feed]
      #raise Exception
    else
      klass = get_klass(feed.text_class.try(:id))
      @nb.train( features, klass )
    end
  end


  # Return hash like { :outlier => [...], :good => [...] }
  def classify feeds, params={}
    classified_hash = {:outlier => [], :good => []}
    feeds.each do |feed|
      features = feed.features_for_text_classifier
      if features.empty?
        classified_hash[:outlier] << feed
      else
        classified = @nb.classify( features )[:class]
        classified == CITY ? classified_hash[:good] << feed : classified_hash[:outlier] << feed
      end
    end
    return classified_hash
  end


  def get_klass( text_class_id )
    text_class_id.nil? ? OUTLIER : CITY
  end


  def preload
    import_data = FileMarshaling.marshal_load(@filename)
    @nb = NaiveBayes::NaiveBayes.new 1.0, :rose, {:rose => { :duplicate_klass => import_data[:rose_duplicate_count].keys.first, :duplicate_count => import_data[:rose_duplicate_count].values.first} }
    @nb.import!( import_data[:docs_count], import_data[:words_count], import_data[:vocabulary],
                 { :average_document_words => import_data[:average_document_words], :rose_duplicate_count => import_data[:rose_duplicate_count] }  )
  end


  def save( filename = @filename )
    FileMarshaling.marshal_save( filename, @nb.export )
  end


  def performance(from_cache=true)
    max_test_data_count = @max_test_data_count
    _, cities_test_data = FeedsHelper.get_train_and_test_feeds( :city, from_cache )

    test_data_count = cities_test_data.count
    test_data_count = max_test_data_count if test_data_count > max_test_data_count

    cities_test_data = cities_test_data.shuffle[0...test_data_count]

    outlier_data = FeedsHelper.get_train_and_test_feeds( :outlier, from_cache )
    outlier_test_data = outlier_data[0...test_data_count]

    confusion_matrix = { CITY => { CITY=>0, OUTLIER =>0 }, OUTLIER => { OUTLIER => 0, CITY => 0 } }

    cities_classified = classify(cities_test_data)
    confusion_matrix[CITY][CITY] = cities_classified[:good].count
    confusion_matrix[CITY][OUTLIER] = cities_classified[:outlier].count

    outlier_classified = classify(outlier_test_data)
    confusion_matrix[OUTLIER][CITY] = outlier_classified[:good].count
    confusion_matrix[OUTLIER][OUTLIER] = outlier_classified[:outlier].count

    return {
             :confusion_matrix => confusion_matrix, :accuracy => accuracy(confusion_matrix),
             :f_measure_city => f_measure(confusion_matrix, CITY), :f_measure_outlier => f_measure(confusion_matrix, OUTLIER)
           }
  end


end