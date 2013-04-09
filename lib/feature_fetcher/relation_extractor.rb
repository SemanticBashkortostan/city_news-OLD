#coding: utf-8
require 'set'

module FeatureFetcher
  class RelationExtractor


    def initialize( dict_type )
      @osm_arr = {                   
                  TextClass.find_by_name("Стерлитамак").id => ["sterlitamak.osm", FeatureFetcher::Osm::STERLITAMAK_BOUNDING_BOX], 
                  TextClass.find_by_name("Салават").id => ["salavat.osm", FeatureFetcher::Osm::SALAVAT_BOUNDING_BOX],
                  TextClass.find_by_name("Нефтекамск").id => ["neftekamsk.osm", FeatureFetcher::Osm::NEFTEKAMSK_BOUNDING_BOX],
                  TextClass.find_by_name("Ишимбай").id => ["ishimbay.osm", FeatureFetcher::Osm::ISHIMBAY_BOUNDING_BOX],
                  TextClass.find_by_name("Уфа").id => ["ufa.osm", FeatureFetcher::Osm::UFA_BOUNDING_BOX]
                }
      @text_class_ids = @osm_arr.keys

      @dict_type = dict_type
      @dict_filename = "#{@dict_type}_vocabulary_hash"      
    end


    # Return dict like { :text_class_id => Set(word1, word2) }
    def get_dict    
      if File.exist?( @dict_filename ) 
        return load_hash(@dict_filename) 
      else
        case @dict_type
        when :lemma then get_lemma_dicts
        when :stem  then get_stem_dicts
        else raise Exception
        end
      end

    end


    # #КОСТЫЛЬ detected
    def form_training_set
      # includes :text_classes and maybe regexp into raw_feature_vector in Feed
      grouped_by_city_training_set = {}
      negative_training_set = []
      text_classes = TextClass.where :id => @text_class_ids      
      dict = get_dict
      feeds = Feed.includes(:text_class).where(:text_class_id => @text_class_ids).all

      feeds.each_with_index do |feed, ind|
        p "proccesed #{feed.id} :: #{ind}/#{feeds.count}"
        feed_feature_vectors = feed.feature_vectors_for_relation_extraction
        next unless feed_feature_vectors 
        feed_feature_vectors.each { |fv|
          text_classes.each do |tc|            
            if fv[:tc_token] =~ Regexp.new( Settings.bayes.regexp[tc.name] ) 
              city_dictionary = dict[tc.id]          
              #КОСТЫЛЬ: Change :ne_lemma to required field    
              if city_dictionary.include?( fv[:ne_lemma] )
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
      save_hash(positive_filename, grouped_by_city_training_set)
      save_hash(negative_filename, negative_training_set)
          
      p [grouped_by_city_training_set.values.count, negative_training_set.count]          
    end


    def get_stem_dicts
      vocabulary = {}
      @osm_arr.each do |klass_id, params|
        print "#{klass_id} processing..."
        osm_feature_fetcher = FeatureFetcher::Osm.new params[1], params[0]
        dict = Dict.new.stem_dict osm_feature_fetcher.get_features
        vocabulary[klass_id] = dict
      end
      save_hash( @dict_filename, vocabulary )
      return vocabulary
    end


    def get_lemma_dicts
      vocabulary = {}
      @osm_arr.each do |klass_id, params|
        print "#{klass_id} processing..."
        osm_feature_fetcher = FeatureFetcher::Osm.new params[1], params[0]
        dict = Dict.new.lemma_dict osm_feature_fetcher.get_features
        vocabulary[klass_id] = dict
      end
      save_hash( @dict_filename, vocabulary )
      return vocabulary
    end


    def load_hash filename
      Marshal.load( File.binread(filename) ) 
    end


    def save_hash filename, vocabulary
      File.open(filename,'wb') do |f|
        f.write Marshal.dump(vocabulary)
      end
    end


  end


end

