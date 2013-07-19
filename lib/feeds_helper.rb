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
module FeedsHelper
  def get_train_and_test_feeds type, from_cache
    if from_cache
      case type
        when :city
          feeds = Feed.cached
          [
              feeds.find_all { |feed| feed.mark_list.include?("dev_train") || feed.mark_list.include?("to_train") || feed.mark_list.include?("was_trainer") },
              feeds.find_all { |feed| feed.mark_list.include?("dev_test") || (feed.mark_list - ["fetched", "production", "classified"]).empty? }
          ]
        when :outlier
          Feed.cached(:filename => 'outlier_cached').to_a.shuffle
      end
    else
      case type
        when :city
          [
              Feed.tagged_with(["dev_train", "to_train", "was_trainer"], :any => true).where(:text_class_id => TextClass.all),
              Feed.tagged_with(["dev_test"], :any => true).where(:text_class_id => TextClass.all) +
                  Feed.tagged_with(["fetched", "production", "classified"], :match_all => true).where(:text_class_id => TextClass.all)
          ]
        when :outlier
          Feed.tagged_with("outlier").all.shuffle
      end
    end

  end


  #TODO: Make outlier_test tag in the future
  def self.get_train_and_test_feeds type, from_cache
    if from_cache
      case type
        when :city
          feeds = Feed.cached
          [
              feeds.find_all { |feed| feed.mark_list.include?("dev_train") || feed.mark_list.include?("to_train") || feed.mark_list.include?("was_trainer") },
              feeds.find_all { |feed| feed.mark_list.include?("dev_test") || (feed.mark_list - ["fetched", "production", "classified"]).empty? }
          ]
        when :outlier
          Feed.cached(:filename => 'outlier_cached').to_a.shuffle
      end
    else
      case type
        when :city
          [
              Feed.tagged_with(["dev_train", "to_train", "was_trainer"], :any => true).where(:text_class_id => TextClass.all),
              Feed.tagged_with(["dev_test"], :any => true).where(:text_class_id => TextClass.all) +
                  Feed.tagged_with(["fetched", "production", "classified"], :match_all => true).where(:text_class_id => TextClass.all)
          ]
        when :outlier
          Feed.tagged_with("outlier").all.shuffle
      end
    end

  end


  def self.get_80_20(array)
    len_80 = (array.length*0.8).floor
    return [array[0...len_80], array[len_80..-1]]
  end
end