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

  def initialize
    @text_classes = TextClass.all
  end


  def init_perform
    feeds_by_month_and_text_class = Feed.where(text_class_id: @text_classes, ancestry: nil).
      where('published_at > ?', 3000.days.ago).order('published_at desc').
      group_by{|feed| [feed.text_class_id, feed.published_at.strftime("%Y-%m-%d")]}

    ActiveRecord::Base.transaction do
      feeds_by_month_and_text_class.each do |group, feeds|
        by_feeds = feeds.dup
        for i in 0...feeds.count
          for j in i+1...by_feeds.count
            next unless by_feeds[j]

            similar_score = feeds[i].similarity(by_feeds[j])
            if similar_score > 0.84
              set_children_to_feed(feeds[i], by_feeds[j], similar_score, false)
            elsif similar_score >= 0.7
              set_children_to_feed(feeds[i], by_feeds[j], similar_score, true)
            end

          end
        end
      end
    end

  end


  def perform_last_feeds last_feeds = nil
    last_feeds_scope ||= Feed.where('published_at > ?', 30.minutes.ago).
        where(text_class_id: @text_classes, ancestry: nil).order('published_at desc')
    compare_feeds_scope = Feed.where(text_class_id: @text_classes).
          where('published_at > ?', 2.days.ago).order('published_at desc')

    ActiveRecord::Base.transaction do
      @text_classes.each do |tc|
        last_feeds = last_feeds_scope.where(:text_class_id => tc.id)
        compare_feeds = compare_feeds_scope.where(:text_class_id => tc.id)
        for i in 0...last_feeds.count
          for j in i+1...compare_feeds.count
            next if !compare_feeds[j] || last_feeds[i].id == compare_feeds[j].id

            similar_score = last_feeds[i].similarity(compare_feeds[j])
            if similar_score > 0.84
              set_children_to_feed(last_feeds[i], compare_feeds[j], similar_score, false)
            elsif similar_score >= 0.7
              set_children_to_feed(last_feeds[i], compare_feeds[j], similar_score, true)
            end

          end
        end
      end
    end
  end


  def set_children_to_feed feed_similar1, feed_similar2, similar_score, only_greater
    if only_greater == false || (only_greater && feed_similar2.similar_score.to_f < similar_score)
      feed_similar2.similar_score = similar_score
      feed_similar2.parent = feed_similar1
      feed_similar2.save!
      feed_similar2 = nil if only_greater == false
    end
  end


end