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

class DataAnalysis


  def initialize
  end


  def boundary_regexp pattern, position
    case position
      when :right
        Regexp.new "#{pattern}+.([[:word:]]+.[[:word:]]+.[[:word:]]+)"
      when :left
        Regexp.new "([[:word:]]+.[[:word:]]+.[[:word:]]+.)#{pattern}"
      else
        Regexp.new "([[:word:]]+.[[:word:]]+.[[:word:]]+.)#{pattern}+.([[:word:]]+.[[:word:]]+.[[:word:]]+)"
    end
  end


  def find_city_names_boundings
    truly_rules = VocabularyEntry.truly.all
    boundings = {:all => [], :left => [], :right => []}
    feeds = Feed.where('text_class_id is not NULL').all
    feeds.each_with_index do |feed, i|
      puts "Processed #{i}/#{feeds.count}"
      truly_rules.each do |ve|
        left_scanned = feed.string_for_classifier.scan boundary_regexp(ve.regexp_rule, :left)
        right_scanned = feed.string_for_classifier.scan boundary_regexp(ve.regexp_rule, :right)
        scanned = feed.string_for_classifier.scan boundary_regexp(ve.regexp_rule, :all)

        boundings[:all] << scanned if scanned.present?
        boundings[:left] << left_scanned if left_scanned.present?
        boundings[:right] << right_scanned if right_scanned.present?
      end
    end

    return boundings
  end

  def filter_left_and_right_uppercase boundings
    filtered = {:left => [], :right => []}
    boundings.each do |bounds|
      bounds.each do |bound|
        p [bound, bound[0].split.last.first]
        if bound[0].split.last.first == bound[0].split.last.mb_chars.first.upcase
          filtered[:left] << bound
        elsif bound[2].split.last.first == bound[2].split.last.mb_chars.first.upcase
          filtered[:right] << bound
        end
      end
    end
    return filtered
  end


end