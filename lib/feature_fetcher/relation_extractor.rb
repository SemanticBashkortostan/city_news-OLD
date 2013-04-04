#coding: utf-8
require 'set'

module FeatureFetcher
  class RelationExtractor


    def initialize
      @osm_arr = {                   
                  TextClass.find_by_name("Стерлитамак").id => ["sterlitamak.osm", FeatureFetcher::Osm::STERLITAMAK_BOUNDING_BOX], 
                  TextClass.find_by_name("Салават").id => ["salavat.osm", FeatureFetcher::Osm::SALAVAT_BOUNDING_BOX],
                  TextClass.find_by_name("Нефтекамск").id => ["neftekamsk.osm", FeatureFetcher::Osm::NEFTEKAMSK_BOUNDING_BOX],
                  TextClass.find_by_name("Ишимбай").id => ["ishimbay.osm", FeatureFetcher::Osm::ISHIMBAY_BOUNDING_BOX],
                  TextClass.find_by_name("Уфа").id => ["ufa.osm", FeatureFetcher::Osm::UFA_BOUNDING_BOX]
                }
      @text_class_ids = @osm_arr.keys
    end


    def get_dictionaries
      filename = 'lemma_vocabolary_hash'
      return Marshal.load (File.binread(filename)) if File.exist?( filename ) 

      vocabolary = {}
      @osm_arr.each do |klass_id, params|
        print "#{klass_id} processing..."
        osm_feature_fetcher = FeatureFetcher::Osm.new params[1], params[0]
        dict = Dict.new.lemma_dict osm_feature_fetcher.get_features
        vocabolary[klass_id] = dict
      end

      File.open(filename,'wb') do |f|
        f.write Marshal.dump(vocabolary)
      end

      return vocabolary
    end


    def get_stem_dicts
      filename = 'stem_vocabolary_hash'
      return Marshal.load (File.binread(filename)) if File.exist?( filename ) 

      vocabolary = {}
      @osm_arr.each do |klass_id, params|
        print "#{klass_id} processing..."
        osm_feature_fetcher = FeatureFetcher::Osm.new params[1], params[0]
        dict = Dict.new.stem_dict osm_feature_fetcher.get_features
        vocabolary[klass_id] = dict
      end

      File.open(filename,'wb') do |f|
        f.write Marshal.dump(vocabolary)
      end

      return vocabolary
    end


    def form_training_set
      # includes :text_classes and maybe regexp into raw_feature_vector in Feed
      grouped_by_city_training_set = {}
      negative_training_set = []
      text_classes = TextClass.where :id => @text_class_ids

      dictionaries = get_dictionaries
      #dictionaries = get_stem_dicts

      dict_lemmas = {}      
      text_classes.each do |tc|
        dict_lemmas[tc.id] = dictionaries[tc.id].collect{|k,v| v[:lemma]}.compact.to_set
      end      

      feeds = Feed.includes(:text_class).where(:text_class_id => @text_class_ids).all
      feeds.each_with_index do |feed, ind|
        p "proccesed #{feed.id} :: #{ind}/#{feeds.count}"
        feed_feature_vectors = feed.feature_vectors_for_relation_extraction
        next unless feed_feature_vectors 
        feed_feature_vectors.each { |fv|
          text_classes.each do |tc|            
            if fv[:tc_token] =~ Regexp.new( Settings.bayes.regexp[tc.name] ) 
              city_dictionary_lemmas = dict_lemmas[tc.id]              
              if city_dictionary_lemmas.include?( fv[:ne_lemma] )
                p "Good! #{fv} #{fv[:ne_lemma]}"
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

      positive_filename = "positive_re_set"
      negative_filename = "negative_re_set"

      File.open(positive_filename,'wb') do |f|
        f.write Marshal.dump(grouped_by_city_training_set)
      end

      File.open(negative_filename,'wb') do |f|
        f.write Marshal.dump(negative_training_set)
      end

      p [grouped_by_city_training_set, grouped_by_city_training_set.values.count]
      p "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      p [negative_training_set, negative_training_set.count]
            
    end


  end
end

