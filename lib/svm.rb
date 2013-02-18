#coding: utf-8

class Svm


  def get_osm_arr
    @osm_arr = {                   
                  TextClass.find_by_name("Стерлитамак").id => ["sterlitamak.osm", FeatureFetcher::Osm::STERLITAMAK_BOUNDING_BOX], 
                  TextClass.find_by_name("Салават").id => ["salavat.osm", FeatureFetcher::Osm::SALAVAT_BOUNDING_BOX],
                  TextClass.find_by_name("Нефтекамск").id => ["neftekamsk.osm", FeatureFetcher::Osm::NEFTEKAMSK_BOUNDING_BOX]
                }
  end


  def get_vector_positions
    @vector_positions= { TextClass.find_by_name("Стерлитамак").id => 0, TextClass.find_by_name("Салават").id => 1, 
                         TextClass.find_by_name("Нефтекамск").id => 2 }
  end


  def make_vocabolary_from_osm
    get_osm_arr
    @vocabolary = {}
    @osm_arr.each do |klass_id, params|
      osm_feature_fetcher = FeatureFetcher::Osm.new params[1], params[0]
      dict = Dict.new.stem_dict_with_weights osm_feature_fetcher.get_features
      @vocabolary[klass_id] = dict
    end
  end


  def get_svm_vectors_from data, vector_length=3
    get_vector_positions    
    vectors = []
    data.each do |feed|
      vector = Array.new vector_length, 0
      str = feed.string_for_classifier
      filtered_str = filter_string str            
      @vocabolary.keys.each do |voc_klass_id|
        @vocabolary[voc_klass_id].keys.each do |word| 
          if filtered_str.scan( word ).present? 
            voc_word = @vocabolary[voc_klass_id][word]
            vector[@vector_positions[ voc_klass_id ] ] += voc_word[:weight]       
          end
        end
      end            
      vectors << [feed.text_class_id, vector] if vector.present?  
    end
    return vectors 
  end


  def filter_string( string )
    words_regexp = /[[:word:]]+/ 
    stemmer= Lingua::Stemmer.new(:language => "ru")  
    string.scan( words_regexp ).map{|word| stemmer.stem( word )}.join(" ").mb_chars.downcase.to_s
  end


  def make_training_and_test_sets
    cities_names = Settings.bayes.klasses
    cities = TextClass.where :name => cities_names

    # Get test and train data
    train_data = Feed.tagged_with("dev_train").where( :text_class_id => cities  )
    test_data  = Feed.tagged_with("dev_test").where( :text_class_id => cities )

    make_vocabolary_from_osm

    # Create svm trainings
    train_vectors = get_svm_vectors_from( train_data )
    test_vectors = get_svm_vectors_from( test_data )
    
    write_to_libsvm_file(train_vectors, 'cities_train')
    write_to_libsvm_file(test_vectors, 'cities_test')
  end


  def write_to_libsvm_file vectors, filename 
    File.open filename, 'w' do |file|
      vectors.each do |vec|
        klass = vec[0]
        vec_str = ""
        vec[1].each_with_index{ |e, i| vec_str << "#{i+1}:#{e} " }
        str = "#{klass}, #{vec_str}"    
        file.puts str
      end
    end
  end

end