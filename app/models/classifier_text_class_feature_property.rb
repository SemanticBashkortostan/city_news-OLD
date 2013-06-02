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
class ClassifierTextClassFeatureProperty < ActiveRecord::Base
  attr_accessible :classifier_id, :feature_count, :text_class_feature_id

  belongs_to :classifier
  belongs_to :text_class_feature


  def self.import_to_naive_bayes(classifier_id)
    words_count = ClassifierTextClassFeatureProperty.includes(:text_class_feature => :feature).where( :classifier_id => classifier_id )

    result_hash = { :docs_count => {}, :words_count => {}, :vocabolary => {} }
    words_count.each do |c_text_class_feature|
     result_hash[:words_count][c_text_class_feature.text_class_feature.text_class_id] ||= {}
     result_hash[:words_count][c_text_class_feature.text_class_feature.text_class_id][c_text_class_feature.text_class_feature.feature.token] = c_text_class_feature.feature_count
    end

    result_hash[:vocabolary] = Set.new( words_count.collect{|e| e.text_class_feature.feature.token } )
    return result_hash
  end
end