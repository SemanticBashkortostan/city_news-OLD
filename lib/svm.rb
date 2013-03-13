#coding: utf-8

class Svm


  def cities_names
    %w(Стерлитамак Салават Нефтекамск Ишимбай Уфа)
  end

  def get_osm_arr
    @osm_arr = {                   
                  TextClass.find_by_name("Стерлитамак").id => ["sterlitamak.osm", FeatureFetcher::Osm::STERLITAMAK_BOUNDING_BOX], 
                  TextClass.find_by_name("Салават").id => ["salavat.osm", FeatureFetcher::Osm::SALAVAT_BOUNDING_BOX],
                  TextClass.find_by_name("Нефтекамск").id => ["neftekamsk.osm", FeatureFetcher::Osm::NEFTEKAMSK_BOUNDING_BOX],
                  TextClass.find_by_name("Ишимбай").id => ["ishimbay.osm", FeatureFetcher::Osm::ISHIMBAY_BOUNDING_BOX],
                  TextClass.find_by_name("Уфа").id => ["ufa.osm", FeatureFetcher::Osm::UFA_BOUNDING_BOX]
                }
  end


  def get_vector_positions
    @vector_positions= { TextClass.find_by_name("Стерлитамак").id => 0, TextClass.find_by_name("Салават").id => 1, 
                         TextClass.find_by_name("Нефтекамск").id => 2, TextClass.find_by_name("Ишимбай").id => 3,
                         TextClass.find_by_name("Уфа").id => 4 }
  end


  def make_vocabolary_from_osm
    get_osm_arr
    filename = 'vocabolary_hash'
    if File.exist? filename
      @vocabolary = Marshal.load (File.binread(filename))
      @all_vocabolary = @vocabolary.values.collect{|hash| hash.keys}.flatten.uniq    
    else
      @vocabolary = {}
      @osm_arr.each do |klass_id, params|
        osm_feature_fetcher = FeatureFetcher::Osm.new params[1], params[0]
        dict = Dict.new.stem_dict_with_weights osm_feature_fetcher.get_features
        @vocabolary[klass_id] = dict
      end
      @all_vocabolary = @vocabolary.values.collect{|hash| hash.keys}.flatten.uniq

      File.open(filename,'wb') do |f|
        f.write Marshal.dump(@vocabolary)
      end
    end
    @test_info << "Vocabolary count: #{@all_vocabolary.count} \n\n"
  end


  def get_svm_vectors_from data, vector_length=nil, klass_id=nil
    vector_length ||= cities_names.count + @all_vocabolary.count
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

            vector[@all_vocabolary.index(word) + cities_names.count] = voc_word[:weight] 
            @test_info << "Word usage in #{@section}: #{word} -- #{voc_word[:weight]} \n"
          end
        end
      end            
      vectors << [(klass_id == feed.text_class_id ? 1 : -1), vector] if vector.present?
    end
    return vectors 
  end


  def filter_string( string )
    words_regexp = /[[:word:]]+/ 
    stemmer= Lingua::Stemmer.new(:language => "ru")  
    string.scan( words_regexp ).map{|word| stemmer.stem( word )}.join(" ").mb_chars.downcase.to_s
  end


  def make_libsvm_model positive_city, train_filename, test_filename
    @test_info << "SVM for #{positive_city} \n\n\n"
    pos_tc = TextClass.find_by_name(positive_city)
    cities = TextClass.where :name => cities_names

    outlier_data = Feed.tagged_with("outlier").all
    # Get test and train data
    pos_train_data = Feed.tagged_with(["dev_train", "to_train", "was_trainer"], :any => true).where( :text_class_id => pos_tc  )
    neg_train_data  = Feed.tagged_with(["dev_train", "to_train", "was_trainer"], :any => true).where( 
                                        :text_class_id => (cities - [pos_tc])  
                                        ).all[0..(pos_train_data.count*0.3).ceil] + outlier_data[0...outlier_data.count/2]
    train_data = pos_train_data + neg_train_data

    test_data  = Feed.tagged_with("dev_test").where( :text_class_id => cities ).all + outlier_data[outlier_data.count/2...outlier_data.count]

    @test_info << "Train data count: #{train_data.count} where pos_train_data is #{pos_train_data.count} and neg is #{neg_train_data.count}\n\n"
    @test_info << "Test data count: #{test_data.count}\n\n"

    # Create svm trainings
    @section = "TRAIN"
    train_vectors = get_svm_vectors_from( train_data, nil, pos_tc.id )
    @section = "TEST"
    test_vectors = get_svm_vectors_from( test_data, nil, pos_tc.id)
    
    write_to_libsvm_file(train_vectors, @file_prefix + train_filename)
    write_to_libsvm_file(test_vectors, @file_prefix + test_filename)  
  end


  def make_training_and_test_sets  
    @file_prefix = "#{Rails.root}/libsvm/with_ufa/"
    @test_info = ""
    make_vocabolary_from_osm 
    make_libsvm_model( "Салават", 'svm_train_salavat', 'svm_test_salavat' )   
    make_libsvm_model( "Стерлитамак", 'svm_train_sterlitamak', 'svm_test_sterlitamak' )   
    make_libsvm_model( "Ишимбай", 'svm_train_ishimbay', 'svm_test_ishimbay' )   
    make_libsvm_model( "Нефтекамск", 'svm_train_neftekamsk', 'svm_test_neftekamsk' )   
    make_libsvm_model( "Уфа", 'svm_train_ufa', 'svm_test_ufa' )   

    File.open(@file_prefix + "test_info", 'w') do |f|
      f.write @test_info
    end
  end

  # ufa [local] 11 -15 86.4809 (best c=32.0, g=0.03125, rate=87.6505)
  def write_to_libsvm_file vectors, filename
    File.open filename, 'w' do |file|
      vectors.each do |vec|
        klass = vec[0]
        vec_str = ""
        vec[1].each_with_index{ |e, i| vec_str << "#{i+1}:#{e} " if e != 0 } 
        str = "#{klass} #{vec_str}"    
        file.puts str
      end
    end
  end

end