#coding: utf-8

module FeatureFetcher
  class RelationExtractor


    def form_training_set
      grouped_by_city_training_set = {}
      negative_training_set = []
      all_text_classes = TextClass.all

      Feed.all.each do |feed|
        feed_feature_vectors = feed.feature_vectors_for_relation_extraction
        next unless feed_feature_vectors 
        feed_feature_vectors.each { |fv|
          all_text_classes.each do |tc|
            if fv[:tc_name] =~ Regexp.new( Settings.bayes.regexp[tc.name] ) 
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

      p grouped_by_city_training_set
      p negative_training_set
    end


  end
end