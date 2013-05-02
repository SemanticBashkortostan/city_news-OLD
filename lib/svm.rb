#coding: utf-8

#TODO: Make logging for Svm. Add weight correction for SVM.
#NOTE: And here we needn't scaling, 'cause data already scaled into [0,1].
class Svm
  include FeedsHelper

  # TRUE_CLASS - for outlier data; FALSE_CLASS - for good data
  TRUE_CLASS = 1
  FALSE_CLASS = -1


  # +filename_prefix+ -examples:( folder1/filename or filename or folder1/folder2/filename )
  def initialize(filename_prefix = "outlier_classifier-new/outlier_city_svm", params={})
    @max_test_data_count = 1000
    @file_path = "#{Rails.root}/"

    @filename =  "#{@file_path}#{filename_prefix}-"

    @from_cache = params[:from_cache]

    path = @filename.split("/")[0...-1].join("/")
    FileUtils.mkdir_p(path) unless File.exists?(path)

    @train_filename = @filename + "train"
    @test_filename = @filename + "test"
    @classify_filename = @filename + "to_classify"
    @classifier_model_filename = @filename + "classifier"
    @test_info_filename = "#{@filename}-test_info"

    make_vocabulary
  end


  # Return hash like { :outlier => [...], :good => [...] }
  def classify(start_feeds, params={})
    need_scaling = params[:need_scaling] || true

    to_classify_vectors, feeds = get_svm_vectors_from(start_feeds, nil, nil, :with_filtered_feeds => true)
    write_to_libsvm_file(to_classify_vectors, @classify_filename)

    if need_scaling
      classify_filename = "#{@classify_filename}.scale"
      system( "svm-scale -s range #{@classify_filename} > #{classify_filename}" )
    else
      classify_filename = "#{@classify_filename}"
    end

    classified_filename = classify_filename + "classified"
    system("svm-predict #{classify_filename} #{@classifier_model_filename} #{classified_filename}")
    classified_hash = {:outlier => [], :good => []}
    File.open(classified_filename, 'r').readlines.each_with_index do |line, ind|
      klass = line.split(" ").first.to_i
      outlier?(klass) ? classified_hash[:outlier] << feeds[ind] : classified_hash[:good] << feeds[ind]
    end
    return classified_hash
  end


  def scale_train_and_test_files
    system( "svm-scale -l 0 -s range #{@train_filename} > #{@train_filename}.scale" )
    system( "svm-scale -r range #{@test_filename} > #{@test_filename}.scale" )
  end


  def choice_optimal_classifier_params train_filename, additional_options
    output = `svm-grid #{additional_options} #{train_filename}`
    params_arr = output.split("\n").last.split(" ")
    {:c => params_arr[0], :g => params_arr[1]}
  end


  # params: +need_scaling+ - true if data needs scaled
  #         +need_optimizing+ - true if you need to run svm-grid to choice g and c
  #         +g, c+ - svm's gamma and cost
  def train_model( params={} )
    if params[:need_scaling]
      scale_train_and_test_files
      train_filename = "#{@train_filename}.scale"
    end
    train_filename ||= @train_filename

    params.merge!(choice_optimal_classifier_params(train_filename, params[:additional_options])) if params[:need_optimizing]
    train_options = ""
    train_options += " -g #{params[:g]}" if params[:g]
    train_options += " -c #{params[:c]}" if params[:c]
    train_options += "  #{params[:additional_options]} " if params[:additional_options]

    system("svm-train #{train_options} #{train_filename} #{@classifier_model_filename}")
  end


  def test_model(scaled_filenames = true)
    scaled_filenames ? test_filename = "#{@test_filename}.scale" : test_filename = "#{@test_filename}"
    system("svm-predict #{test_filename} #{@classifier_model_filename} #{test_filename}-predicted")
  end


  def make_training_and_test_files
    @test_info = ""
    train_vectors, test_vectors = make_libsvm_train_and_test_vectors
    make_libsvm_train_and_test_files( train_vectors, test_vectors )
    make_test_info_file
  end


  def outlier?(klass)
    klass == TRUE_CLASS
  end


  # Currently return only confusion matrix
  def performance( scaled=true, test_filename=@test_filename, predict_filename=@test_filename+"-predicted" )

    test_filename, predict_filename = "#{@test_filename}.scale", "#{@test_filename}.scale-predicted" if scaled
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


  protected


  #NOTE: Т.е тут мы получаем вектор признаков к которому уже применили regexp_rule из VocabularyEntry. И как же тогда формировать вектор признаков??? А у нас всё равно регескпы мапятса в токены)
  # А хотя там домен всё равно не участвовал, т.к у него token - nil!
  def get_svm_vectors_from( data, vector_length=nil, klass_id=nil, options={} )
    vector_length ||= @vocabulary.count
    vectors = []
    filtered_feeds = []
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
        if vector.present? && vector_include_one
          filtered_feeds << feed
          vectors << [(klass_id == feed.text_class.try(:id) ? TRUE_CLASS : FALSE_CLASS), vector]
        end
      end
    end
    return [vectors, filtered_feeds] if options[:with_filtered_feeds]
    return vectors
  end

  # 32, 0.5
  def make_libsvm_train_and_test_files( train_vectors, test_vectors )
    write_to_libsvm_file(train_vectors, @train_filename)
    write_to_libsvm_file(test_vectors, @test_filename)
  end


  def make_libsvm_train_and_test_vectors
    @test_info << "SVM for input data filtering.\n Filename is #{@filename} \n\n\n "
    cities_train_data, cities_test_data = get_train_and_test_feeds(:city, @from_cache)

    test_data_count = cities_test_data.count
    test_data_count = @max_test_data_count if test_data_count > @max_test_data_count

    cities_test_data = cities_test_data.shuffle[0...test_data_count]

    outlier_data = get_train_and_test_feeds( :outlier, @from_cache)
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

    return [train_vectors, test_vectors]
  end


  def make_vocabulary
    @vocabulary = VocabularyEntry.pluck(:token).uniq.compact
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


  def make_test_info_file
    File.open(@test_info_filename, 'w'){ |f| f.write @test_info }
  end


end


# Default 30 04 13: Accuracy = 90.2985% (847/938) (classification)
#  {1=>{1=>266, -1=>2}, -1=>{1=>89, -1=>581}}

# With additional vocabulary entry
#irb(main):082:0> svm.performance false
#=> {1=>{1=>615, -1=>1}, -1=>{1=>38, -1=>948}}

# With weighting
#=> {1=>{1=>616, -1=>0}, -1=>{1=>40, -1=>946}}

# ROSE-MNB
#"City: 5589, 1000; Outlier: 34626, 1000"
#[12771, 348]
#{-1=>{-1=>979, 1=>8}, 1=>{1=>659, -1=>6}}
#0.9915254237288136
#=> 0.9915254237288136


