#coding: utf-8

class Svm

  # TRUE_CLASS - for outlier data; FALSE_CLASS - for good data
  TRUE_CLASS = 1
  FALSE_CLASS = -1


  # Maybe add timestamp into filenames?
  def initialize
    # Maximum test data count
    @max_test_data = 1000
    @file_prefix = "#{Rails.root}/"

    @filename =  "#{@file_prefix}outlier_city_svm-"
    @train_filename = @filename + "train"
    @test_filename = @filename + "test"
    @classify_filename = @filename + "to_classify"
    @classifier_filename = @filename + "classifier"

    make_vocabulary
  end


  #TODO: Add tags to outlier and good feeds
  def classify( feeds )
    to_classify_vectors = get_svm_vectors_from(feeds)
    write_to_libsvm_file(to_classify_vectors, @classify_filename)

    classified_filename = @filename + "classified"
    system("svm-predict #{@classify_filename} #{@classifier_filename} #{classified_filename}")
    File.open(classified_filename, 'r').readlines.each_with_index do |line, ind|
      klass = line.split(" ").first.to_i
      feeds.delete(ind) if outlier?(klass)
    end
    return feeds
  end


  def train_model

  end


  def make_training_and_test_sets
    @test_info = ""
    make_libsvm_model
    wirte_test_info
  end


  def outlier?(klass)
    klass == TRUE_CLASS
  end


  protected


  #NOTE: Т.е тут мы получаем вектор признаков к которому уже применили regexp_rule из VocabularyEntry. И как же тогда формировать вектор признаков??? А у нас всё равно регескпы мапятса в токены)
  # А хотя там домен всё равно не участвовал, т.к у него token - nil!
  def get_svm_vectors_from( data, vector_length=nil, klass_id=nil )
    vector_length ||= @vocabulary.count
    vectors = []
    data.each do |feed|
      vector = Array.new vector_length, 0
      feature_vector = feed.features_for_text_classifier
      if feature_vector
        vector_include_one = false
        feature_vector.each do |token|
          index = @vocabulary.index(token)
          if index # Потом можно попробовать term_freq использовать вместо has_term?
            vector[index] = 1
            vector_include_one = true
          end
        end
        vectors << [(klass_id == feed.text_class_id ? TRUE_CLASS : FALSE_CLASS), vector] if vector.present? && vector_include_one
      end
    end
    return vectors
  end


  def make_libsvm_model
    @test_info << "SVM for input data filtering \n\n\n"
    cities_train_data = Feed.tagged_with(["dev_train", "to_train", "was_trainer"], :any => true).where( :text_class_id => TextClass.all )
    cities_test_data  = Feed.tagged_with(["dev_test"], :any => true).where( :text_class_id => TextClass.all ) +
                        Feed.tagged_with(["fetched", "production", "classified"], :match_all => true).where( :text_class_id => TextClass.all )

    test_data_count = cities_test_data.count
    test_data_count = @max_test_data if test_data_count > @max_test_data

    cities_test_data = cities_test_data.shuffle[0...test_data_count]

    outlier_data = Feed.tagged_with("outlier").all.shuffle
    outlier_test_data = outlier_data[0...test_data_count]
    outlier_train_data = outlier_data[test_data_count...outlier_data.count]

    @test_info << "Cities train data count: #{cities_train_data.count}; Outlier train data count:#{outlier_train_data.count} \n\n"
    @test_info << "Test data count: #{test_data_count};\n\n"

    @section = "TRAIN"
    train_data = outlier_train_data + cities_train_data
    train_vectors = get_svm_vectors_from( train_data, nil, nil )

    @section = "TEST"
    test_data = outlier_test_data + cities_test_data
    test_vectors = get_svm_vectors_from( test_data, nil, nil )

    write_to_libsvm_file(train_vectors, @train_filename)
    write_to_libsvm_file(test_vectors, @test_filename)
  end



  def make_vocabulary
    @vocabulary = VocabularyEntry.accepted.pluck(:token).uniq.compact
  end


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


  def wirte_test_info( filename = "test_info")
    File.open(@file_prefix + filename, 'w') do |f|
      f.write @test_info
    end
  end


  def performance( test_filename=@test_filenamet, predict_filename )
    test, predict = [], []
    File.open(test_filename, 'r').readlines.each do |line|
      test << line.split(" ").first.to_i
    end
    File.open(predict_filename, 'r').readlines.each do |line|
      predict << line.split(" ").first.to_i
    end

    confusion_matrix = {TRUE_CLASS => {TRUE_CLASS=>0, FALSE_CLASS=>0}, FALSE_CLASS => {TRUE_CLASS=>0, FALSE_CLASS=>0}}
    for i in 0...test.count
      confusion_matrix[test[i]][predict[i]] += 1
    end
    return confusion_matrix
  end

end