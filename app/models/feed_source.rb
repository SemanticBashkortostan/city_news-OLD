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


class FeedSource < ActiveRecord::Base
  attr_accessible :text_class_id, :url

  belongs_to :text_class
  has_many :feeds

  validates :url, :uniqueness => true

  scope :active, where(:active => true)


  def available?
    !Feedzirra::Feed.fetch_and_parse( url ).nil?
  end


  def domain
    url.split("/")[2]
  end
end
