#coding: utf-8
module NaiveBayes


	class NaiveBayes


    def get_features( string )
      get_naive_features(string.clone)  
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


    # Возвращает features, которые являются однокоренными с городом и домен
    # Работает по принципу Multinomial NB
    # Находим features у строки. В конфигурационном файле хранится отображение regexp на название feature
    # Если feature найден, то он заменяется на отображение regexp на название feature. 
    # Например, "В Уфе есть клуб Салават Юлаев" --> "В Уфа есть клуб Уфа"
    # Это сделано чтобы не было конфликтов с другими regexp в городах( например, Салават Юлаев )
    def get_naive_features string
      features = []
      Settings.bayes.shorten_klasses.each do |short_name|
        regexp_hash = { :regexp => Regexp.new( Settings.bayes.regexp[short_name][0] ), :name => Settings.bayes.regexp[short_name][1] }
        feature = scan( string, regexp_hash  )
        if feature
          features += feature 
          string.gsub! regexp_hash[:regexp], feature.first         
        end
      end

      domain = string.scan( Regexp.new( Settings.bayes.regexp["domain"][0] ) )
      features << domain[0].split("/")[2] unless domain.empty?        
      features.compact
    end


    # Работает по принципу Boolean Multinomial NB
    def get_osm_features string      
      filtered_string = filter_string( string )
      features = []
      @vocabolary.each do |word|
        unless filtered_string.scan(word).blank?
          features << word 
        end
      end

      features.uniq
    end


    def filter_string( string )
      words_regexp = /[[:word:]]+/ 
      stemmer= Lingua::Stemmer.new(:language => "ru")  
      string.scan( words_regexp ).map{|word| stemmer.stem( word )}.join(" ").mb_chars.downcase.to_s
    end


    def import_osm_features
      # Example: { :japanese => {"Tokyo" => 3} } means that in class :japanese, word "Tokyo" was 3 times
      @klass_words_count = {}
      @vocabolary = Set.new      
      osm_arr = {                   
                  TextClass.find_by_name("Ишимбай").id => ["ishimbay.osm", FeatureFetcher::Osm::ISHIMBAY_BOUNDING_BOX], 
                  TextClass.find_by_name("Стерлитамак").id => ["sterlitamak.osm", FeatureFetcher::Osm::STERLITAMAK_BOUNDING_BOX], 
                  TextClass.find_by_name("Салават").id => ["salavat.osm", FeatureFetcher::Osm::SALAVAT_BOUNDING_BOX],
                  TextClass.find_by_name("Нефтекамск").id => ["neftekamsk.osm", FeatureFetcher::Osm::NEFTEKAMSK_BOUNDING_BOX] 
                }
      osm_arr.each do |city, params|
        @klass_docs_count[city] = @klass_docs_count[city].to_i + 1
        @klass_words_count[city] ||= {}  
        osm_feature_fetcher = FeatureFetcher::Osm.new params[1], params[0]
        osm_feature_fetcher.get_features.each do |feature_arr|
          filtered_feature = filter_string( feature_arr[0] )
          @vocabolary << filtered_feature
          @klass_words_count[city][filtered_feature] = @klass_words_count[city][filtered_feature].to_i + 1
        end
      end

    end


  end


end