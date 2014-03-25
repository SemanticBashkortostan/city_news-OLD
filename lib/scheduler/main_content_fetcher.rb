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

class Scheduler::MainContentFetcher
  def initialize(limit_count)
    @limit_count = limit_count
  end

  def fetch_and_set_main_content_to_feeds
    feeds.all.each do |feed|
      begin
        content = ContentExtractor.get(:pipeline, url: feed.url)
        feed.main_html_content = content['main_html_content']
        feed.save!
      rescue Exception => e
        Honeybadger.context({:feed_id => feed.id, :feed_url => feed.url})
        Honeybadger.notify(e)
        raise e if Rails.env != 'production'
      end

    end
  end


  private


  def feeds
    Feed.with_any_text_class.without_main_content.with_active_feed_source.
             with_extractable_main_content_feed_source.order('published_at desc').
             limit(@limit_count)
  end
end