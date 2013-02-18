require 'nokogiri'

module FeatureFetcher


  class Osm


    ISHIMBAY_BOUNDING_BOX = {:top => 53.4731, :left => 55.9502, :bottom => 53.3999, :right => 56.1322}
    SALAVAT_BOUNDING_BOX = {:top => 53.3862, :left => 55.8489, :bottom => 53.3054, :right => 55.999}
    STERLITAMAK_BOUNDING_BOX = {:top => 53.7523, :left => 55.7659, :bottom => 53.5619, :right => 56.1744}
    NEFTEKAMSK_BOUNDING_BOX = {:top => 56.1428, :left => 54.1406, :bottom => 55.9649, :right => 54.4221}


    # +bounding_box+ is a Hash, look at up
    def initialize(bounding_box, filename )
      @bounding_box = bounding_box
      @filename = "#{Rails.root}/lib/feature_fetcher/osm_maps/#{filename}"
    end


    def get_part_of_map
      bashkortostan = "#{Rails.root}/lib/feature_fetcher/osm_maps/bashkortostan.osm"      
      exec = "osmosis --read-xml file=\"#{bashkortostan}\" --bounding-box top=#{@bounding_box[:top]} left=#{@bounding_box[:left]} \
              bottom=#{@bounding_box[:bottom]} right=#{@bounding_box[:right]} --write-xml file=\"#{@filename}\""
      system exec
    end


    # Возвращает массив с элементами вида - [name, amenity, osm_id]
    def get_features
      xmlfeed = Nokogiri::XML(open(@filename))
      rows = xmlfeed.xpath("//*[@k=\"name\"]")
      features = []
      rows.each do |row|
        name = row.attributes['v'].value
        osm_id = row.parent.attributes["id"].value
        amenity = row.parent.xpath("tag[@k=\"amenity\"]").first
        amenity = amenity.attributes["v"].value if amenity
        features << [name, amenity, osm_id]
      end                
      return features
    end


  end


end
