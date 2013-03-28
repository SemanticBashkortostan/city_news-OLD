#coding: utf-8
require 'set'

module FeatureFetcher
  class RelationExtractor


    def get_dictionaries
      filename = 'lemma_vocabolary_hash'
      return Marshal.load (File.binread(filename)) if File.exist?( filename )
        
      osm_arr = {                   
                  TextClass.find_by_name("Стерлитамак").id => ["sterlitamak.osm", FeatureFetcher::Osm::STERLITAMAK_BOUNDING_BOX], 
                  TextClass.find_by_name("Салават").id => ["salavat.osm", FeatureFetcher::Osm::SALAVAT_BOUNDING_BOX],
                  TextClass.find_by_name("Нефтекамск").id => ["neftekamsk.osm", FeatureFetcher::Osm::NEFTEKAMSK_BOUNDING_BOX],
                  TextClass.find_by_name("Ишимбай").id => ["ishimbay.osm", FeatureFetcher::Osm::ISHIMBAY_BOUNDING_BOX],
                  TextClass.find_by_name("Уфа").id => ["ufa.osm", FeatureFetcher::Osm::UFA_BOUNDING_BOX]
                }

      vocabolary = {}
      osm_arr.each do |klass_id, params|
        osm_feature_fetcher = FeatureFetcher::Osm.new params[1], params[0]
        dict = Dict.new.lemma_dict osm_feature_fetcher.get_features
        vocabolary[klass_id] = dict
      end

      File.open(filename,'wb') do |f|
        f.write Marshal.dump(vocabolary)
      end

      return vocabolary
    end


    def form_training_set
      grouped_by_city_training_set = {}
      negative_training_set = []
      all_text_classes = TextClass.all

      dictionaries = get_dictionaries
      dict_lemmas = {}      
      all_text_classes.each do |tc|
        dict_lemmas[tc.id] = dictionaries[tc.id].collect{|k,v| v[:lemma]}.compact.to_set
      end

      Feed.all.each do |feed|
        feed_feature_vectors = feed.feature_vectors_for_relation_extraction
        next unless feed_feature_vectors 
        feed_feature_vectors.each { |fv|
          all_text_classes.each do |tc|
            if fv[:tc_name] =~ Regexp.new( Settings.bayes.regexp[tc.name] ) 
              city_dictionary_lemmas = dict_lemmas[tc.id]
              if city_dictionary_lemmas.include?( fv[:ne_name_lemma] )
                grouped_by_city_training_set[tc.id] ||= []
                grouped_by_city_training_set[tc.id] << fv
                break
              else
                negative_training_set << fv
                break
              end

            end
          end 
        }             
      end

      p grouped_by_city_training_set.count
      p negative_training_set.count
    end


  end
end