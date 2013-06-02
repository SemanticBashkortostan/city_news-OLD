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
module FileMarshaling
  def marshal_save filename, vocabulary
    File.open(filename, 'wb') do |f|
      f.write Marshal.dump(vocabulary)
    end
  end

  def marshal_load filename
    Marshal.load(File.binread(filename))
  end


  def self.marshal_save filename, vocabulary
    File.open(filename, 'wb') do |f|
      f.write Marshal.dump(vocabulary)
    end
  end


  def self.marshal_load filename
    Marshal.load(File.binread(filename))
  end
end