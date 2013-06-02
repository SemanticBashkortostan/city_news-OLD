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
class TextClass < ActiveRecord::Base
  attr_accessible :name

  has_many :feeds

  has_many :text_class_features
  has_many :features, :through => :text_class_features
  has_many :feed_sources

  has_many :docs_counts
  has_many :classifiers, :through => :docs_counts

  has_and_belongs_to_many :vocabulary_entries
end