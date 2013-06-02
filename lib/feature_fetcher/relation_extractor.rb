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
#coding: utf-8
require 'set'

module FeatureFetcher
  class RelationExtractor


    include FileMarshaling
    CachedFeed = Struct.new( :id, :feature_vectors_for_relation_extraction )
    def initialize( dict_type=:stem )
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
        return marshal_load(@dict_filename) 
      else
        case @dict_type
        when :lemma then get_lemma_dicts
        when :stem  then get_stem_dicts
        else raise Exception
        end
      end

    end


    def generate_dict_from_vocabulary_entry
      dict = {}
      @text_class_ids.each do |id|
        dict[id] = VocabularyEntry.accepted.for_city(id).collect(&:token).to_set
      end
      return dict
    end

    def generate_truly_rules_from_vocabulary_entry
      truly_rules = {}
      @text_class_ids.each do |id|
        truly_rules[id] = Regexp.new(VocabularyEntry.make_regexp_for_truly_entries(id)[0])
      end
      return truly_rules
    end


    # Write [feature_vector, feed.id] into sets
    def form_training_set
      # includes :text_classes and maybe regexp into raw_feature_vector in Feed
      positive_training_set = []
      negative_training_set = []
      text_classes = TextClass.where :id => @text_class_ids      
      dict = generate_dict_from_vocabulary_entry
      truly_rules = generate_truly_rules_from_vocabulary_entry
      feeds = Feed.includes(:text_class).where(:text_class_id => @text_class_ids).all

      feeds.each_with_index do |feed, ind|
        p "proccesed #{feed.id} :: #{ind}/#{feeds.count}"
        feed_feature_vectors = feed.feature_vectors_for_relation_extraction
        next unless feed_feature_vectors 
        feed_feature_vectors.each { |fv|
          text_classes.each do |tc|            
            if fv[:tc_stem] =~ truly_rules[tc.id] && fv[:tc_stem] != fv[:ne_stem] && fv[:ne_stem].length > 1
              city_dictionary = dict[tc.id]
              if city_dictionary.include?( fv[:ne_stem] )
                positive_training_set << [fv, feed.id]
                break
              else
                negative_training_set << [fv, feed.id]
                break
              end
            end
          end 
        }             
      end

      positive_filename = "positive_re_set-new"
      negative_filename = "negative_re_set-new"
      marshal_save(positive_filename, positive_training_set)
      marshal_save(negative_filename, negative_training_set)        
    end


    def preload_feeds_data
      if !@feeds
        feeds = Feed.includes(:text_class).where(:text_class_id => @text_class_ids).all
        @feeds = []
        feeds.each do |feed|
          @feeds << CachedFeed.new(feed.id, feed.feature_vectors_for_relation_extraction)
        end
      end
      return @feeds
    end


    def extract_vectors_for_relation_extractor(dict = nil)
      set = []
      dict ||= generate_dict_from_vocabulary_entry
      truly_rules = generate_truly_rules_from_vocabulary_entry
      feeds = @feeds
      feeds.each_with_index do |feed, ind|
        p "proccesed #{feed.id} :: #{ind}/#{feeds.count}"
        feed_feature_vectors = feed.feature_vectors_for_relation_extraction
        next unless feed_feature_vectors
        feed_feature_vectors.each { |fv|
          @text_class_ids.each do |tc_id|
           if fv[:tc_stem] =~ truly_rules[tc_id] && fv[:tc_stem] != fv[:ne_stem] && fv[:ne_stem].length > 1
             city_dictionary = dict[tc_id]
             if city_dictionary.include?( fv[:ne_stem] )
               set << [fv, feed.id]
               break
             end
           end
         end
        }
      end
      return set

    end


    def make_big_vocabulary
      big_vocabulary = Set.new

      filename = "positive_re_set"
      positive_re_hash = marshal_load filename      
      positive_re_hash.each do |k, v|
        p v.count  
        v.each do |vector|
          big_vocabulary << vector[:ne_stem]
          big_vocabulary << WordProcessor.stem(vector[:tc_token], vector[:tc_quoted])
        end
      end
      
      big_vocabulary += get_dict.values.to_set.flatten
      p big_vocabulary.count
      marshal_save( "big_vocabulary", big_vocabulary )
    end


    def big_vocabulary
      marshal_load("big_vocabulary")      
    end


    def get_stem_dicts
      vocabulary = {}
      @osm_arr.each do |klass_id, params|
        print "#{klass_id} processing..."
        osm_feature_fetcher = FeatureFetcher::Osm.new params[1], params[0]
        dict = Dict.new.stem_dict osm_feature_fetcher.get_features
        vocabulary[klass_id] = dict
        p dict.count
      end
      marshal_save( @dict_filename, vocabulary )
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
      marshal_save( @dict_filename, vocabulary )
      return vocabulary
    end





  end


end