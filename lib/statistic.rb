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
module Statistic

  def precision( confusion_matrix, klass )
    confusion_matrix[klass][klass].to_i / confusion_matrix.values.inject(0.0){ |s,e| s += e[klass].to_f }
  end


  def recall(confusion_matrix, klass)
    confusion_matrix[klass][klass].to_f / confusion_matrix[klass].values.sum
  end


  def accuracy( confusion_matrix )
    val = 0.0
    denom = 0.0 # Count of all documents in test
    klasses = confusion_matrix.keys
    klasses.each do |klass|
      denom += confusion_matrix.values.inject(0.0){ |s,e| s += e[klass].to_f }
    end
    klasses.each do |klass|
      val += confusion_matrix[klass][klass].to_i / denom
    end
    val
  end


  def f_measure(confusion_matrix, klass, beta=1)
    precision = precision(confusion_matrix, klass)
    recall = recall(confusion_matrix, klass)
    ( (beta**2 + 1) * precision * recall )/( beta**2 * precision + recall )
  end

end