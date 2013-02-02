#coding: utf-8
module NaiveBayes


	class NaiveBayes


    def get_features( string )
      features = []
      Settings.bayes.shorten_klasses.each do |short_name|
        regexp_hash = { :regexp => Regexp.new( Settings.bayes.regexp[short_name][0] ), :name => Settings.bayes.regexp[short_name][1] }
        feature = scan( string, regexp_hash  )
        if feature
          features += feature          
        end
      end

      domain = string.scan( Regexp.new( Settings.bayes.regexp["domain"][0] ) )
      features << domain[0].split("/")[2] unless domain.empty?        
      features.compact
    end


    def lemmatize word
      (`./lib/turglem-client #{word}`).split(" ")[1]
    end


    # Возвращает массив feature с количеством повторений в строке.
    # Например, ["Уфа", "Уфа"]
    def scan string, regexp_hash
      matched = string.scan( regexp_hash[:regexp] )
      unless matched.empty?
        [ regexp_hash[:name] ] * matched.count 
      end  
    end


    def save_to_database
      klass_words_count = export[:words_count]
      klass_words_count.each do |klass_id, words_count|
        words_count.each do |word, cnt|
          begin
            text_class_feature = TextClassFeature.find_or_create_by_text_class_id_and_feature_id( klass_id, Feature.find_or_create_by_token( word ).id )
            text_class_feature.feature_count = cnt
            text_class_feature.save! if text_class_feature.changed?
          rescue Exception => e
            str = "Error in save_to_database in naive_bayes.rb, word-#{word}, cnt-#{cnt}. Exception: #{e}"
            p str
            BayesLogger.bayes_logger.error str
          end
        end
      end

    end


  end


end