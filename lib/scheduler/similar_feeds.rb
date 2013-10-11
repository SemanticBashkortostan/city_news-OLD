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
class Scheduler::SimilarFeeds


  def self.perform
    feeds_by_month_and_text_class = Feed.where(text_class_id: TextClass.all, ancestry: nil).
      group_by{|feed| [feed.text_class_id, feed.published_at.strftime("%Y-%m")]}

    feeds_by_month_and_text_class.each do |group, feeds|
      by_feeds = feeds.dup
      for i in 0...feeds.count
        for j in i+1...by_feeds.count
          next unless by_feeds[j]

          similar_score = feeds[i].similarity(by_feeds[j])
          if similar_score >= 0.8
            set_children_to_feed(feeds[i], by_feeds[j], similar_score, false)
          elsif similar_score > 0.4
            set_children_to_feed(feeds[i], by_feeds[j], similar_score, true)
          end

        end
      end
    end

  end


  def self.set_children_to_feed feed_similar1, feed_similar2, similar_score, only_greater
    if only_greater == false || (only_greater && feed_similar2.similar_score.to_f < similar_score)
      feed_similar2.similar_score = similar_score
      feed_similar2.parent = feed_similar1
      feed_similar2.save!
      feed_similar2 = nil if only_greater == false
    end
  end


end