#coding: utf-8
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

namespace :statistic do
  desc "Get statustic of feeds with [City] words"
  task :feeds_city => :environment do
    regexp_salavat = /(Салав+[[:word:]]+|САЛАВ+[[:word:]]+|салав+[[:word:]]+)/
    regexp_ufa = /(Уф+[[:word:]]+|УФ+[[:word:]]+|уфи+[[:word:]]+)/
    regexp_str = /(Стерл+[[:word:]]+|СТЕРЛ+[[:word:]]+|стерл+[[:word:]]+)/

    statistic = {}
    cities_names = ["Уфа", "Стерлитамак", "Салават"]
    text_classes = TextClass.where :name => cities_names
    Feed.where(:text_class_id => text_classes).find_each do |feed|
      str = feed.title + " " + feed.summary
      if not str.scan( regexp_ufa ).blank?
        statistic[:ufa] = statistic[:ufa].to_i + 1
      elsif not str.scan( regexp_salavat ).blank?
        statistic[:salavat] = statistic[:salavat].to_i + 1
      elsif not str.scan( regexp_str ).blank?
        statistic[:sterlitamak] = statistic[:sterlitamak].to_i + 1
      end
    end

    p [statistic, Feed.count]
    with_city_val = statistic.values.inject(0) { |e, sum| sum += e } / Feed.count.to_f
    p with_city_val
  end
end