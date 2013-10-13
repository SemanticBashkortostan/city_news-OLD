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

require 'zlib'

module FuzzyTextMatch

  def similarity feed2
    feed1 = self
    begin
      prepared1 = prepare(feed1)
      prepared2 = prepare(feed2)
    rescue ArgumentError => e
      Rails.logger.error "#{e} with feeds_ids[#{feed1.id}, #{feed2.id}]"
      return 0.0
    end

    if prepared1[:doc_crc] == prepared2[:doc_crc]
      return 1.0
    else
      return prepared1[:words_crc].intersection(prepared2[:words_crc]).count.to_f /
             [ prepared1[:good_words_count], prepared2[:good_words_count] ].min
    end
  end


  def temp_storage_for_similars
    {}
  end


  private


  def prepare feed
    return temp_storage_for_similars[feed.id] if temp_storage_for_similars[feed.id]
    text = (good_words(title).count > 4 ? feed.title : feed.summary)

    raise( ArgumentError, "text cant be blank!" ) if text.blank?

    words = extract_and_normalize_15_good_words text

    temp_storage_for_similars[feed.id] = { :doc_crc => doc_crc = Zlib::crc32(text),
                               :words_crc => words.map{ |word| Zlib::crc32(word) }.to_set,
                               :good_words_count => good_words(text).count }
    return temp_storage_for_similars[feed.id]
  end


  # Extract words which length > 2 symbols
  def extract_and_normalize_15_good_words text
    all_good_words = good_words(text).sort_by{|str| -str.length}
    all_good_words[0...15].map{ |word| normalize!(word) }
  end


  def good_words text
    text.scan(/[[:word:]]{3,}+/)
  end


  # Test without stemming and with stemming
  def normalize!(word)
    stemmer= Lingua::Stemmer.new(:language => "ru")
    normalized = stemmer.stem( word ).mb_chars.downcase.to_s
    return normalized
  end
end