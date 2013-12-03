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
require 'clockwork'

require File.expand_path('../../config/environment', __FILE__)
require "#{Rails.root}/lib/scheduler/main_content_fetcher"


include Clockwork


every(10.minutes, 'production_feeds:fetch_main_content') do
  Scheduler::MainContentFetcher.new(100).fetch_and_set_main_content_to_feeds
end
