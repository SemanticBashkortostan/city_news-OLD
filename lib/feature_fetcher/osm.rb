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
require 'nokogiri'

module FeatureFetcher


  class Osm


    ISHIMBAY_BOUNDING_BOX = {:top => 53.4731, :left => 55.9502, :bottom => 53.3999, :right => 56.1322}
    SALAVAT_BOUNDING_BOX = {:top => 53.3862, :left => 55.8489, :bottom => 53.3054, :right => 55.999}
    STERLITAMAK_BOUNDING_BOX = {:top => 53.7523, :left => 55.7659, :bottom => 53.5619, :right => 56.1744}
    NEFTEKAMSK_BOUNDING_BOX = {:top => 56.1428, :left => 54.1406, :bottom => 55.9649, :right => 54.4221}
    UFA_BOUNDING_BOX = {:top => 54.8943, :left => 55.7638, :bottom => 54.5258, :right => 56.21}


    # +bounding_box+ is a Hash, look at up
    def initialize(bounding_box, filename )
      @bounding_box = bounding_box
      @filename = "#{Rails.root}/project_files/osm_maps/#{filename}"
    end


    def get_part_of_map
      bashkortostan = "#{Rails.root}/project_files/bashkortostan.osm"
      raise Exception unless File.exist?(bashkortostan)
      exec = "osmosis --read-xml file=\"#{bashkortostan}\" --bounding-box top=#{@bounding_box[:top]} left=#{@bounding_box[:left]} \
              bottom=#{@bounding_box[:bottom]} right=#{@bounding_box[:right]} --write-xml file=\"#{@filename}\""
      system exec
    end


    # Return array with elements like [name, amenity, osm_id]
    # where name.length > 2
    def get_features
      xmlfeed = Nokogiri::XML(open(@filename))
      rows = xmlfeed.xpath("//*[@k=\"name\"]")
      features = []
      rows.each do |row|
        name = row.attributes['v'].value
        osm_id = row.parent.attributes["id"].value
        amenity = row.parent.xpath("tag[@k=\"amenity\"]").first
        amenity = amenity.attributes["v"].value if amenity
        features << [name, amenity, osm_id] if name.length > 2
      end                
      return features
    end


    def self.make_maps_from_text_classes
      osm_arr = [
                  ["sterlitamak.osm", FeatureFetcher::Osm::STERLITAMAK_BOUNDING_BOX],
                  ["salavat.osm", FeatureFetcher::Osm::SALAVAT_BOUNDING_BOX],
                  ["neftekamsk.osm", FeatureFetcher::Osm::NEFTEKAMSK_BOUNDING_BOX],
                  ["ishimbay.osm", FeatureFetcher::Osm::ISHIMBAY_BOUNDING_BOX],
                  ["ufa.osm", FeatureFetcher::Osm::UFA_BOUNDING_BOX]
                ]
      osm_arr.each do |(filename, bounding_box)|
        osm = FeatureFetcher::Osm.new bounding_box, filename
        osm.get_part_of_map
      end
    end


  end


end