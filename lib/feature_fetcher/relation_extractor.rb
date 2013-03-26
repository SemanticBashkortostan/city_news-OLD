#coding: utf-8

module FeatureFetcher


  class RelationExtractor
    DEFAULT_SAMPLES = [["Уф", "Салават Юлаев"], ["Стерлит", "Сода"], 
                       ["Салават", "Газпром Нефтехим"], ["Уф", "Урал"], ["Уф", "Ялалов"]]

    def initialize samples=DEFAULT_SAMPLES
      @training_samples = samples 
    end


    def extract_relations
      @training_samples.each do |sample|
        search = Feed.solr_search do 
          keywords( sample.join(" ") ) do
            highlight :title
            highlight :summary
          end
          paginate :page => 1, :per_page => 999999 
        end

        hits = {:title => [], :summary => []}
        search.hits.each do |hit|
          hit.highlights(:title).each do |highlight|
            hl_str = [0, nil, hit.primary_key]
            hl_str[1] = highlight.format do |word|                           
              word =~ Regexp.new(sample[0]) ? hl_str[0] = 0 : hl_str[0] = 1                              
              "*#{word}*"
            end            
            hits[:title] << hl_str
          end

          hit.highlights(:summary).each do |highlight|
            hl_str = [0, nil, hit.primary_key]
            hl_str[1] = highlight.format do |word|                           
              word =~ Regexp.new(sample[0]) ? hl_str[0] = 0 : hl_str[0] = 1                              
              "*#{word}*"
            end
            hits[:summary] << [hit.stored(:summary), hl_str]
          end
        end

        p hits
        gets
      end      

    end

  end

end