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
class WordProcessor
  def self.lemmatize( token, quoted=false )
    return token if quoted
    
    lemmatized = []
    words = token.split(" ")
    words.each do |word|
      lemm_word = (`./lib/turglem-client #{word}`).split(" ")[1]
      lemm_word = word if lemm_word.blank?
      lemmatized << lemm_word
    end
    return lemmatized.join(" ")
  end


  def self.stem(feature, quoted)
    return feature if quoted
    stemmed = Lingua.stemmer( feature.split(" "), :language => :ru )
    return stemmed.join(" ") if stemmed.is_a?( Array )
    return stemmed
  end
end