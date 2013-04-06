#coding: utf-8

class ReBayesTest
  include Statistic

  attr_accessor :positive_set, :negative_set, :nb
  def initialize( name = "" )
    @name = name
    make_train_and_test_sets

    @nb = NaiveBayes::NaiveBayes.new 
  end


  def train
    @positive_set.each do |example|
      fv = make_feature_vector(example)  
      @nb.train(fv, 1)
    end

    @negative_set.each do |example|
      fv = make_feature_vector(example)  
      @nb.train(fv, -1)
    end    
  end


  # Отфильтровать данные по типа {tc_token => Уфа, ne_token => Уфе} типа город - город
  def test
    confusion_matrix = { 1 => {}, -1 => {} }

    @test_positive_set.each do |example|
      fv = make_feature_vector(example) 
      classified = @nb.classify(fv)
      
      #p [1, classified[:class]]
      #p example if classified[:class] != 1
      
      confusion_matrix[1][classified[:class]] = confusion_matrix[1][classified[:class]].to_i + 1
    end

    @test_negative_set.each do |example|
      fv = make_feature_vector(example) 
      classified = @nb.classify(fv)
      
      #p [-1, classified[:class]] 
      #p example if classified[:class] != -1

      confusion_matrix[-1][classified[:class]] = confusion_matrix[-1][classified[:class]].to_i + 1
    end
    p confusion_matrix

    p ["f-measure", 1, f_measure( confusion_matrix, 1 )]
    p ["f-measure", -1, f_measure( confusion_matrix, -1 )]

    p ["precision, recall", 1, precision(confusion_matrix, 1), recall(confusion_matrix, 1)]
    p ["precision, recall", -1, precision(confusion_matrix, -1), recall(confusion_matrix, -1)]

    p ["#{@name}accuracy", accuracy(confusion_matrix)]
    print "\n"
  end


  def make_feature_vector example
    # without :distance 
    ending_keys = [ :tc_right_context, :tc_left_context, :ne_right_context, :ne_left_context, :tc_token]
    to_quant_keys = [:distance]
    feature_keys = [           
                          :tc_is_first_token,
                          :tc_right_context, :tc_left_context, :tc_quoted,
                          :has_other_cities, :in_one_sent, :tc_word_position,
                          :tc_same_as_feed, :distance,
                          :ne_is_first_token, :ne_right_context, 
                          :ne_left_context, :ne_quoted, :tc_token
                    ]
    feature_vector = []    
    feature_keys.each do |key|
      if example[key] && ending_keys.include?(key)
        if example[key].length > 3
          example_val = example[key][-3..-1]
        else
          example_val = example[key][-1]
        end
      elsif example[key] && to_quant_keys.include?(key)
        if key == :distance
          case example[key]
            when 0..2 then example_val = :small 
            when 3..4 then example_val = :mid 
            else example_val = :big
          end
        end 
      else
        example_val = example[key]
      end

      val = "#{key}_#{example_val}"
      feature_vector << val 
    end
    return feature_vector
  end


  def filter_training_set
    # filtered_positive_set = [].to_set
    # @positive_set.each_with_index do |example, i|
    #   puts "#{i}/#{@positive_set.count}"
    #   fv = make_feature_vector(example)  
    #   classified = @nb.classify(fv)
    #   filtered_positive_set << example if classified[:class] == 1
    # end              
    @positive_set = load_set "positive_re_set"   
    p [@positive_set.count, @negative_set.count]
    #@negative_set = @negative_set.shuffle[0...@positive_set.count]
    #0.33 - 1/2 - all positive set 
    #
    @nb = NaiveBayes::NaiveBayes.new 
  end


  def self.run(name = "")
    rbt = ReBayesTest.new( name )
    rbt.train
    rbt.get_rn_set
    
    rbt.filter_training_set    
    rbt.train
    
    rbt.test
  end


  def get_rn_set
    negative_set = Set.new
    @negative_set.each_with_index do |example,i| 
      fv = make_feature_vector(example) 
      classified = @nb.classify fv    
      #puts "#{i}/#{@negative_set.count}, #{classified[:class]}"
      negative_set << example if (classified[:class] == -1)
    end
    p [negative_set.count, @negative_set.count, @positive_set.count, negative_set.to_a.sample]
    #gets 
    @negative_set = negative_set.to_a
  end


  def extract_features_for_dipre example, train=false   
    ending_keys = [ :tc_right_context, :tc_left_context, :ne_right_context, :ne_left_context]
    # other_keys = []
    other_keys = [ :tc_is_first_token, :has_other_cities, :in_one_sent, 
                   :tc_word_position, :tc_same_as_feed, :ne_is_first_token ] 
    if  (example[:ne_right_context] || example[:ne_left_context]) #&& example[:in_one_sent] 
      #!example[:ne_is_first_token]
      example.keys.each do |key|
        if ending_keys.include?(key) && example[key]
          if example[key].length > 3
            example[key] = example[key][-3..-1]
          else
            example[key] = example[key][-1]
          end        
        elsif not(other_keys.include?(key))
          example[key] = nil 
        end 
      end
    end
  end


  def custom_dipre_patterns
    dipre_hash = {}
    positive_filename = "positive_re_set"

    @positive_set = load_set positive_filename
    @positive_set.uniq!
    @positive_set.each do |example|
      extract_features_for_dipre(example, true)      
      dipre_hash[example] = dipre_hash[example].to_i + 1
    end
        
    patterns = Hash[dipre_hash.find_all{|k,v| v > 1}]
    p patterns.count
    return patterns        
  end


  # Удаляем если и там и там tc, ne =~= tc. Удаляем токены длины меньше 3
  def test_dipre
    patterns = custom_dipre_patterns
    pos = Set.new
    @test_negative_set.each do |example|
      cloned = example.clone
      extract_features_for_dipre example
      if patterns[example]
        p "BAD!" 
        p cloned
      end
    end

     @test_positive_set.each do |example|
      cloned = example.clone
      extract_features_for_dipre example
      if patterns[example]
        p "GOOD!" 
        p cloned
      end
    end
    
    gets

    cnt = 0
    @negative_set.each do |example|
      cloned = example.clone
      extract_features_for_dipre example
      if patterns[example]
        p "???!" 
        p cloned
        #gets 
        cnt += 1
      end
    end
    p cnt

    nil

  end

  # {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"в ", 
  #   :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>0, :tc_word_position=>false, :tc_same_as_feed=>true, 
  #   :ne_is_first_token=>nil, :ne_token=>"Башинформ", :ne_right_context=>nil, :ne_left_context=>"агентству ", :ne_quoted=>true, :ne_lemma=>"Башинформ"}



  protected



  def make_train_and_test_sets
    preload_not_negative_and_not_positive_arrs

    positive_filename = "positive_re_set"
    negative_filename = "negative_re_set"
    test_positive_filename = "positive_test_set"
    test_negative_filename = "negative_test_set"
    @positive_set = load_set positive_filename    
    @negative_set = load_set negative_filename   
    
    filter_sets

    @test_positive_set = load_set( test_positive_filename )    - @not_positive_arr + @not_negative_arr
    @test_negative_set = load_set( test_negative_filename )    - @not_negative_arr + @not_positive_arr
    #@test_positive_set = @test_positive_set[0...@test_negative_set.count]


    # @positive_set = @positive_set - @test_positive_set    
    # @negative_set = (@negative_set - @test_negative_set).shuffle[0...@positive_set.count]
    # @positive_set = @positive_set[0...@negative_set.count]
    
    #save_set "shuffled_negative_set#{@name}", @negative_set

  end


  def filter_sets
    pos_cnt = (@positive_set.count*(1/3.0)).ceil
    spies = @positive_set[0...pos_cnt].clone
    @negative_set += spies 
    @positive_set[0...pos_cnt] = @positive_set[pos_cnt...@positive_set.count]
    

    # dict_lemmas = FeatureFetcher::RelationExtractor.new.get_dict_lemmas    
    

    # filtered_negative_train = Set.new
    # other_dicts_hash = {}
    # @negative_set.each_with_index do |example,i|
    #   puts "#{i}/#{@negative_set.count}"
    #   current_dict = dict_lemmas[example[:text_class_id]]

    #   if other_dicts_hash[example[:text_class_id]]
    #     other_dicts = other_dicts_hash[example[:text_class_id]]
    #   else
    #     cloned_dict_lemma = dict_lemmas.clone
    #     cloned_dict_lemma.delete(example[:text_class_id])
    #     other_dicts_hash[example[:text_class_id]] ||= cloned_dict_lemma.values.flatten.to_set.flatten                      
    #     other_dicts = other_dicts_hash[example[:text_class_id]]
    #   end
      
    #   if !current_dict.include?( example[:ne_lemma] ) && other_dicts.include?( example[:ne_lemma] )         
    #     filtered_negative_train << example if example[:ne_token].split(" ").count == 1
    #   end
    # end
    #p [@negative_set.count, filtered_negative_train.count, @positive_set.count, @positive_set.sample, @negative_set.sample, filtered_negative_train.to_a.sample]
    #@negative_set = filtered_negative_train.to_a    
  end


  def load_set filename
    loaded_hash = Marshal.load(File.binread(filename))     
    return loaded_hash.values.to_a.flatten if loaded_hash.is_a?( Hash )
    return loaded_hash.flatten
  end


  def save_set filename, set
    File.open(filename,'wb') do |f|
      f.write Marshal.dump(set)
    end
  end




  def preload_not_negative_and_not_positive_arrs
    @not_positive_arr = [
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе VI Зимних", :tc_right_context=>"международных", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Уфе", :ne_right_context=>"но", :ne_left_context=>"в ", :ne_quoted=>nil, :ne_lemma=>"УФА"},
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>3, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Всего", :ne_right_context=>"за", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"ВЕСЬ"},
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Снежная", :ne_right_context=>"глыба", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"СНЕЖНЫЙ"},
                              {:text_class_id=>3, :tc_is_first_token=>nil, :tc_token=>" Стерлитамаке", :tc_right_context=>"произошёл", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>0, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Всю", :ne_right_context=>"ночь", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"ВЕСЬ"},                              
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфа", :tc_right_context=>nil, :tc_left_context=>"рейса ", :tc_quoted=>nil, :has_other_cities=>true, :in_one_sent=>false, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Приволжское", :ne_right_context=>"следственное", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"ПРИВОЛЖСКИЙ"},
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Салават Юлаев", :tc_right_context=>"нанес", :tc_left_context=>"Всего ", :tc_quoted=>true, :has_other_cities=>false, :in_one_sent=>true, :distance=>2, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Всего", :ne_right_context=>nil, :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"ВЕСЬ"},
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"митинг", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Домом", :ne_right_context=>"профсоюзов", :ne_left_context=>"перед ", :ne_quoted=>nil, :ne_lemma=>"ДОМ"},
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"ДПС Уфы", :tc_right_context=>"появится", :tc_left_context=>"полку ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>0, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"ДПС", :ne_right_context=>"начнет", :ne_left_context=>"полку ", :ne_quoted=>nil, :ne_lemma=>"ДПС"},
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфы", :tc_right_context=>"разместило", :tc_left_context=>"благоустройства ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Подземный", :ne_right_context=>"переход", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"ПОДЗЕМНЫЙ"},
                              {:text_class_id=>5, :tc_is_first_token=>true, :tc_token=>"Прокуратура Нефтекамска", :tc_right_context=>"пресекла", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>6, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Детской", :ne_right_context=>"художественной", :ne_left_context=>"учащихся ", :ne_quoted=>nil, :ne_lemma=>"ДЕТСКИЙ"},
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфимский", :tc_right_context=>"гарнизонный", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"За", :ne_right_context=>"взрывы", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"ЗА"},
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>4, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Новый", :ne_right_context=>"состав", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"НОВЫЙ"},
                              {:text_class_id=>3, :tc_is_first_token=>nil, :tc_token=>" Стерлитамакском", :tc_right_context=>"районе", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>0, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Украинский", :ne_right_context=>"историко", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"УКРАИНСКИЙ"},
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>3, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Меньше", :ne_right_context=>"месяца", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"МАЛЕНЬКИЙ"},
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфимочки", :tc_right_context=>"сгорели", :tc_left_context=>"Надежды ", :tc_quoted=>true, :has_other_cities=>false, :in_one_sent=>true, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Надежды", :ne_right_context=>nil, :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"НАДЕЖДА"},                              
                              {:text_class_id=>2, :tc_is_first_token=>nil, :tc_token=>"Салавате", :tc_right_context=>nil, :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Салавате", :ne_right_context=>"и", :ne_left_context=>"в ", :ne_quoted=>nil, :ne_lemma=>"САЛАВАТ"},
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>" Уфе", :tc_right_context=>"полицейские", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Центра", :ne_right_context=>"кадровых", :ne_left_context=>"вывеской ", :ne_quoted=>nil, :ne_lemma=>"ЦЕНТР"},
                              {:text_class_id=>3, :tc_is_first_token=>true, :tc_token=>"Стерлитамак", :tc_right_context=>nil, :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Салават", :ne_right_context=>nil, :ne_left_context=>"городах ", :ne_quoted=>nil, :ne_lemma=>"САЛАВАТ"},
                              {:text_class_id=>5, :tc_is_first_token=>nil, :tc_token=>"Нефтекамска", :tc_right_context=>nil, :tc_left_context=>"города ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>3, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Библиотека", :ne_right_context=>"приглашает", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"БИБЛИОТЕКА"},
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"пройдут", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Средняя", :ne_right_context=>"цена", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"СРЕДНИЙ"},
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфы:", :tc_right_context=>"горнолыжного", :tc_left_context=>"площадок ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Всего", :ne_right_context=>"в", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"ВЕСЬ"},
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>" Уфе", :tc_right_context=>"стартует", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Карьера", :ne_right_context=>nil, :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"КАРЬЕРА"},                              
                              {:text_class_id=>5, :tc_is_first_token=>nil, :tc_token=>" Нефтекамске", :tc_right_context=>"сотрудник", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>0, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Управление", :ne_right_context=>"собственной", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"УПРАВЛЕНИЕ"},
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"по", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>2, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Средняя", :ne_right_context=>"цена", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"СРЕДНИЙ"},
                              {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфа", :tc_right_context=>nil, :tc_left_context=>"город ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>3, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Специалистам", :ne_right_context=>"учреждений", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"СПЕЦИАЛИСТ"}
                    ]
    @not_negative_arr = [
                                 {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>0, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Башинформ", :ne_right_context=>nil, :ne_left_context=>"агентству ", :ne_quoted=>true, :ne_lemma=>"Башинформ"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"мест", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"КПРФ", :ne_right_context=>"проводить", :ne_left_context=>"разрешило ", :ne_quoted=>nil, :ne_lemma=>"КПРФ"},
                                {:text_class_id=>3, :tc_is_first_token=>true, :tc_token=>"Стерлитамак", :tc_right_context=>nil, :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>4, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Отделом по молодежной политики", :ne_right_context=>nil, :ne_left_context=>"и ", :ne_quoted=>true, :ne_lemma=>"Отделом по молодежной политики"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>" Уфе", :tc_right_context=>"пройдет", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"РСПК", :ne_right_context=>"пройдет", :ne_left_context=>"крови ", :ne_quoted=>nil, :ne_lemma=>"РСПК"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"начнутся", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Дней Шаляпина", :ne_right_context=>nil, :ne_left_context=>"с ", :ne_quoted=>nil, :ne_lemma=>"ДЕНЬ ШАЛЯПИН"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"унес", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"ГУ МЧС", :ne_right_context=>"по", :ne_left_context=>"служба ", :ne_quoted=>nil, :ne_lemma=>"ГУ МЧС"},
                                {:text_class_id=>2, :tc_is_first_token=>true, :tc_token=>"Салават", :tc_right_context=>"встречает", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Крещенский Сочельник", :ne_right_context=>nil, :ne_left_context=>"встречает ", :ne_quoted=>nil, :ne_lemma=>"КРЕЩЕНСКИЙ СОЧЕЛЬНИК"},
                                {:text_class_id=>3, :tc_is_first_token=>nil, :tc_token=>"Стерлитамак", :tc_right_context=>nil, :tc_left_context=>"город ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>1, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Молодежного Совета", :ne_right_context=>"нового", :ne_left_context=>"состав ", :ne_quoted=>nil, :ne_lemma=>"МОЛОДЕЖНЫЙ СОВЕТ"},
                                {:text_class_id=>3, :tc_is_first_token=>true, :tc_token=>"Стерлитамак", :tc_right_context=>"или", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>4, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"КВН", :ne_right_context=>"в", :ne_left_context=>"лиги ", :ne_quoted=>nil, :ne_lemma=>"КВНА"},
                                {:text_class_id=>1, :tc_is_first_token=>nil, :tc_token=>" Ишимбае", :tc_right_context=>"пройдет", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>4, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Шихан Время", :ne_right_context=>"встречи", :ne_left_context=>"кафе ", :ne_quoted=>nil, :ne_lemma=>"ШИХАН ВРЕМЯ"},
                                {:text_class_id=>2, :tc_is_first_token=>nil, :tc_token=>"Салават", :tc_right_context=>nil, :tc_left_context=>"город ", :tc_quoted=>nil, :has_other_cities=>true, :in_one_sent=>false, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"БАНК УРАЛСИБ", :ne_right_context=>"является", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"БАНК УРАЛСИБ"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфы", :tc_right_context=>"зарегистрировано", :tc_left_context=>"района ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Калининского", :ne_right_context=>"района", :ne_left_context=>"комиссией ", :ne_quoted=>nil, :ne_lemma=>"КАЛИНИНСКИЙ"},
                                {:text_class_id=>4, :tc_is_first_token=>true, :tc_token=>"УФМС", :tc_right_context=>"по", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Управлении Федеральной", :ne_right_context=>"миграционной", :ne_left_context=>"в ", :ne_quoted=>nil, :ne_lemma=>"УПРАВЛЕНИЕ ФЕДЕРАЛЬНЫЙ"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>" Уфе", :tc_right_context=>"пройдет", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>3, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Нефтяник", :ne_right_context=>nil, :ne_left_context=>"культуры ", :ne_quoted=>true, :ne_lemma=>"Нефтяник"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>3, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"ФСИН", :ne_right_context=>"по", :ne_left_context=>"наказаний ", :ne_quoted=>nil, :ne_lemma=>"ФСИН"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"на", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Акбузат", :ne_right_context=>"сыграют", :ne_left_context=>"ипподроме ", :ne_quoted=>true, :ne_lemma=>"Акбузат"},
                                {:text_class_id=>2, :tc_is_first_token=>nil, :tc_token=>"Салават", :tc_right_context=>nil, :tc_left_context=>"города ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>3, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Республики Башкортостан", :ne_right_context=>"по", :ne_left_context=>"первенство ", :ne_quoted=>nil, :ne_lemma=>"РЕСПУБЛИКА БАШКОРТОСТАН"},
                                {:text_class_id=>3, :tc_is_first_token=>nil, :tc_token=>" Стерлитамакском", :tc_right_context=>"колледже", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>8, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>" Кристина Кузнецова", :ne_right_context=>"и", :ne_left_context=>"и ", :ne_quoted=>nil, :ne_lemma=>"КРИСТИНА КУЗНЕЦОВ"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"пройдет", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Динамо", :ne_right_context=>nil, :ne_left_context=>"клуба ", :ne_quoted=>true, :ne_lemma=>"Динамо"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфу", :tc_right_context=>"прилетел", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Рудольфу Нуриеву", :ne_right_context=>nil, :ne_left_context=>"посвященный ", :ne_quoted=>nil, :ne_lemma=>"РУДОЛЬФ НУРИЕВ"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфы", :tc_right_context=>"победили", :tc_left_context=>"из ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Динамо", :ne_right_context=>"принимало", :ne_left_context=>"котором ", :ne_quoted=>true, :ne_lemma=>"Динамо"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>" Уфе", :tc_right_context=>nil, :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>3, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Open Ufa — Полосатый тигр", :ne_right_context=>nil, :ne_left_context=>"каратэ ", :ne_quoted=>true, :ne_lemma=>"Open Ufa — Полосатый тигр"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"городу ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>1, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Юрий Шевчук", :ne_right_context=>"и", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"ЮРИЙ ШЕВЧУК"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"на", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>4, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Юрия Шевчука", :ne_right_context=>"и", :ne_left_context=>"концерт ", :ne_quoted=>nil, :ne_lemma=>"ЮРИЙ ШЕВЧУК"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>" Уфе", :tc_right_context=>nil, :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"России", :ne_right_context=>nil, :ne_left_context=>"команды ", :ne_quoted=>nil, :ne_lemma=>"РОССИЯ"},
                                {:text_class_id=>4, :tc_is_first_token=>true, :tc_token=>"Уфа Ответчики: ООО Торговый", :tc_right_context=>"центр", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>0, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"АС Республики Башкортостан", :ne_right_context=>"проведет", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"АС РЕСПУБЛИКА БАШКОРТОСТАН"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфимского", :tc_right_context=>"района", :tc_left_context=>"администрации ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>3, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Михаил Давыдов", :ne_right_context=>nil, :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"МИХАИЛ ДАВЫДОВ"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>" Уфу", :tc_right_context=>"он", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Ильдар Абдразаков", :ne_right_context=>"работает", :ne_left_context=>"время ", :ne_quoted=>nil, :ne_lemma=>"ИЛЬДАР АБДРАЗАК"},
                                {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>3, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Динамо", :ne_right_context=>"приложит", :ne_left_context=>"стадиона ", :ne_quoted=>true, :ne_lemma=>"Динамо"},
                                {:text_class_id=>1, :tc_is_first_token=>true, :tc_token=>"Ишимбай", :tc_right_context=>"37", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Юрий Малкин", :ne_right_context=>"осуждён", :ne_left_context=>"летний ", :ne_quoted=>nil, :ne_lemma=>"ЮРИЙ МАЛКИН"},
                                {:text_class_id=>4, :tc_is_first_token=>true, :tc_token=>"Уфимская", :tc_right_context=>"художница", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>0, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Олеся Сапожкова", :ne_right_context=>nil, :ne_left_context=>"художница ", :ne_quoted=>nil, :ne_lemma=>"ОЛЕСЬ САПОЖКОВА"}
                                ]
  end
end






### NEGATIVE
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>0, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Башинформ", :ne_right_context=>nil, :ne_left_context=>"агентству ", :ne_quoted=>true, :ne_lemma=>"Башинформ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"мест", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"КПРФ", :ne_right_context=>"проводить", :ne_left_context=>"разрешило ", :ne_quoted=>nil, :ne_lemma=>"КПРФ"}
# {:text_class_id=>3, :tc_is_first_token=>true, :tc_token=>"Стерлитамак", :tc_right_context=>nil, :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>4, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Отделом по молодежной политики", :ne_right_context=>nil, :ne_left_context=>"и ", :ne_quoted=>true, :ne_lemma=>"Отделом по молодежной политики"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>" Уфе", :tc_right_context=>"пройдет", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"РСПК", :ne_right_context=>"пройдет", :ne_left_context=>"крови ", :ne_quoted=>nil, :ne_lemma=>"РСПК"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"начнутся", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Дней Шаляпина", :ne_right_context=>nil, :ne_left_context=>"с ", :ne_quoted=>nil, :ne_lemma=>"ДЕНЬ ШАЛЯПИН"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"унес", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"ГУ МЧС", :ne_right_context=>"по", :ne_left_context=>"служба ", :ne_quoted=>nil, :ne_lemma=>"ГУ МЧС"}
# {:text_class_id=>2, :tc_is_first_token=>true, :tc_token=>"Салават", :tc_right_context=>"встречает", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Крещенский Сочельник", :ne_right_context=>nil, :ne_left_context=>"встречает ", :ne_quoted=>nil, :ne_lemma=>"КРЕЩЕНСКИЙ СОЧЕЛЬНИК"}
# {:text_class_id=>3, :tc_is_first_token=>nil, :tc_token=>"Стерлитамак", :tc_right_context=>nil, :tc_left_context=>"город ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>1, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Молодежного Совета", :ne_right_context=>"нового", :ne_left_context=>"состав ", :ne_quoted=>nil, :ne_lemma=>"МОЛОДЕЖНЫЙ СОВЕТ"}
# {:text_class_id=>3, :tc_is_first_token=>true, :tc_token=>"Стерлитамак", :tc_right_context=>"или", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>4, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"КВН", :ne_right_context=>"в", :ne_left_context=>"лиги ", :ne_quoted=>nil, :ne_lemma=>"КВНА"}
# {:text_class_id=>1, :tc_is_first_token=>nil, :tc_token=>" Ишимбае", :tc_right_context=>"пройдет", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>4, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Шихан Время", :ne_right_context=>"встречи", :ne_left_context=>"кафе ", :ne_quoted=>nil, :ne_lemma=>"ШИХАН ВРЕМЯ"}
# {:text_class_id=>2, :tc_is_first_token=>nil, :tc_token=>"Салават", :tc_right_context=>nil, :tc_left_context=>"город ", :tc_quoted=>nil, :has_other_cities=>true, :in_one_sent=>false, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"БАНК УРАЛСИБ", :ne_right_context=>"является", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"БАНК УРАЛСИБ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфы", :tc_right_context=>"зарегистрировано", :tc_left_context=>"района ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Калининского", :ne_right_context=>"района", :ne_left_context=>"комиссией ", :ne_quoted=>nil, :ne_lemma=>"КАЛИНИНСКИЙ"}
# {:text_class_id=>4, :tc_is_first_token=>true, :tc_token=>"УФМС", :tc_right_context=>"по", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Управлении Федеральной", :ne_right_context=>"миграционной", :ne_left_context=>"в ", :ne_quoted=>nil, :ne_lemma=>"УПРАВЛЕНИЕ ФЕДЕРАЛЬНЫЙ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>" Уфе", :tc_right_context=>"пройдет", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>3, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Нефтяник", :ne_right_context=>nil, :ne_left_context=>"культуры ", :ne_quoted=>true, :ne_lemma=>"Нефтяник"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>3, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"ФСИН", :ne_right_context=>"по", :ne_left_context=>"наказаний ", :ne_quoted=>nil, :ne_lemma=>"ФСИН"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"на", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Акбузат", :ne_right_context=>"сыграют", :ne_left_context=>"ипподроме ", :ne_quoted=>true, :ne_lemma=>"Акбузат"}
# {:text_class_id=>2, :tc_is_first_token=>nil, :tc_token=>"Салават", :tc_right_context=>nil, :tc_left_context=>"города ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>3, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Республики Башкортостан", :ne_right_context=>"по", :ne_left_context=>"первенство ", :ne_quoted=>nil, :ne_lemma=>"РЕСПУБЛИКА БАШКОРТОСТАН"}
# {:text_class_id=>3, :tc_is_first_token=>nil, :tc_token=>" Стерлитамакском", :tc_right_context=>"колледже", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>8, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>" Кристина Кузнецова", :ne_right_context=>"и", :ne_left_context=>"и ", :ne_quoted=>nil, :ne_lemma=>"КРИСТИНА КУЗНЕЦОВ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"пройдет", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Динамо", :ne_right_context=>nil, :ne_left_context=>"клуба ", :ne_quoted=>true, :ne_lemma=>"Динамо"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфу", :tc_right_context=>"прилетел", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Рудольфу Нуриеву", :ne_right_context=>nil, :ne_left_context=>"посвященный ", :ne_quoted=>nil, :ne_lemma=>"РУДОЛЬФ НУРИЕВ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфы", :tc_right_context=>"победили", :tc_left_context=>"из ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Динамо", :ne_right_context=>"принимало", :ne_left_context=>"котором ", :ne_quoted=>true, :ne_lemma=>"Динамо"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>" Уфе", :tc_right_context=>nil, :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>3, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Open Ufa — Полосатый тигр", :ne_right_context=>nil, :ne_left_context=>"каратэ ", :ne_quoted=>true, :ne_lemma=>"Open Ufa — Полосатый тигр"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"городу ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>1, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Юрий Шевчук", :ne_right_context=>"и", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"ЮРИЙ ШЕВЧУК"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"на", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>4, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Юрия Шевчука", :ne_right_context=>"и", :ne_left_context=>"концерт ", :ne_quoted=>nil, :ne_lemma=>"ЮРИЙ ШЕВЧУК"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>" Уфе", :tc_right_context=>nil, :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"России", :ne_right_context=>nil, :ne_left_context=>"команды ", :ne_quoted=>nil, :ne_lemma=>"РОССИЯ"}
# {:text_class_id=>4, :tc_is_first_token=>true, :tc_token=>"Уфа Ответчики: ООО Торговый", :tc_right_context=>"центр", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>0, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"АС Республики Башкортостан", :ne_right_context=>"проведет", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"АС РЕСПУБЛИКА БАШКОРТОСТАН"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфимского", :tc_right_context=>"района", :tc_left_context=>"администрации ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>3, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Михаил Давыдов", :ne_right_context=>nil, :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"МИХАИЛ ДАВЫДОВ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>" Уфу", :tc_right_context=>"он", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Ильдар Абдразаков", :ne_right_context=>"работает", :ne_left_context=>"время ", :ne_quoted=>nil, :ne_lemma=>"ИЛЬДАР АБДРАЗАК"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>3, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Динамо", :ne_right_context=>"приложит", :ne_left_context=>"стадиона ", :ne_quoted=>true, :ne_lemma=>"Динамо"}
# {:text_class_id=>1, :tc_is_first_token=>true, :tc_token=>"Ишимбай", :tc_right_context=>"37", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Юрий Малкин", :ne_right_context=>"осуждён", :ne_left_context=>"летний ", :ne_quoted=>nil, :ne_lemma=>"ЮРИЙ МАЛКИН"}





### POSITIVE
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе VI Зимних", :tc_right_context=>"международных", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Уфе", :ne_right_context=>"но", :ne_left_context=>"в ", :ne_quoted=>nil, :ne_lemma=>"УФА"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>3, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Всего", :ne_right_context=>"за", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"ВЕСЬ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Снежная", :ne_right_context=>"глыба", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"СНЕЖНЫЙ"}
# {:text_class_id=>3, :tc_is_first_token=>nil, :tc_token=>" Стерлитамаке", :tc_right_context=>"произошёл", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>0, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Всю", :ne_right_context=>"ночь", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"ВЕСЬ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"УФСКН:", :tc_right_context=>"служба", :tc_left_context=>"регионального ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>2, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Башкортостану", :ne_right_context=>"возбудил", :ne_left_context=>"по ", :ne_quoted=>nil, :ne_lemma=>"БАШКОРТОСТАН"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфа", :tc_right_context=>nil, :tc_left_context=>"рейса ", :tc_quoted=>nil, :has_other_cities=>true, :in_one_sent=>false, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Приволжское", :ne_right_context=>"следственное", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"ПРИВОЛЖСКИЙ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Салават Юлаев", :tc_right_context=>"нанес", :tc_left_context=>"Всего ", :tc_quoted=>true, :has_other_cities=>false, :in_one_sent=>true, :distance=>2, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Всего", :ne_right_context=>nil, :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"ВЕСЬ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"митинг", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Домом", :ne_right_context=>"профсоюзов", :ne_left_context=>"перед ", :ne_quoted=>nil, :ne_lemma=>"ДОМ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"ДПС Уфы", :tc_right_context=>"появится", :tc_left_context=>"полку ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>0, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"ДПС", :ne_right_context=>"начнет", :ne_left_context=>"полку ", :ne_quoted=>nil, :ne_lemma=>"ДПС"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфы", :tc_right_context=>"разместило", :tc_left_context=>"благоустройства ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Подземный", :ne_right_context=>"переход", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"ПОДЗЕМНЫЙ"}
# {:text_class_id=>5, :tc_is_first_token=>true, :tc_token=>"Прокуратура Нефтекамска", :tc_right_context=>"пресекла", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>6, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Детской", :ne_right_context=>"художественной", :ne_left_context=>"учащихся ", :ne_quoted=>nil, :ne_lemma=>"ДЕТСКИЙ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфимский", :tc_right_context=>"гарнизонный", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"За", :ne_right_context=>"взрывы", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"ЗА"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>4, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Новый", :ne_right_context=>"состав", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"НОВЫЙ"}
# {:text_class_id=>3, :tc_is_first_token=>nil, :tc_token=>" Стерлитамакском", :tc_right_context=>"районе", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>0, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Украинский", :ne_right_context=>"историко", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"УКРАИНСКИЙ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>nil, :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>3, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Меньше", :ne_right_context=>"месяца", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"МАЛЕНЬКИЙ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфимочки", :tc_right_context=>"сгорели", :tc_left_context=>"Надежды ", :tc_quoted=>true, :has_other_cities=>false, :in_one_sent=>true, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Надежды", :ne_right_context=>nil, :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"НАДЕЖДА"}
# {:text_class_id=>5, :tc_is_first_token=>nil, :tc_token=>" Нефтекамске", :tc_right_context=>"за", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>3, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Нефтяников", :ne_right_context=>nil, :ne_left_context=>"улице ", :ne_quoted=>nil, :ne_lemma=>"НЕФТЯНИК"}
# {:text_class_id=>2, :tc_is_first_token=>nil, :tc_token=>"Салавате", :tc_right_context=>nil, :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Салавате", :ne_right_context=>"и", :ne_left_context=>"в ", :ne_quoted=>nil, :ne_lemma=>"САЛАВАТ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>" Уфе", :tc_right_context=>"полицейские", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Центра", :ne_right_context=>"кадровых", :ne_left_context=>"вывеской ", :ne_quoted=>nil, :ne_lemma=>"ЦЕНТР"}
# {:text_class_id=>3, :tc_is_first_token=>true, :tc_token=>"Стерлитамак", :tc_right_context=>nil, :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>nil, :ne_token=>"Салават", :ne_right_context=>nil, :ne_left_context=>"городах ", :ne_quoted=>nil, :ne_lemma=>"САЛАВАТ"}
# {:text_class_id=>5, :tc_is_first_token=>nil, :tc_token=>"Нефтекамска", :tc_right_context=>nil, :tc_left_context=>"города ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>3, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Библиотека", :ne_right_context=>"приглашает", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"БИБЛИОТЕКА"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"пройдут", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Средняя", :ne_right_context=>"цена", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"СРЕДНИЙ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфы:", :tc_right_context=>"горнолыжного", :tc_left_context=>"площадок ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>2, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Всего", :ne_right_context=>"в", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"ВЕСЬ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>" Уфе", :tc_right_context=>"стартует", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>1, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Карьера", :ne_right_context=>nil, :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"КАРЬЕРА"}
# {:text_class_id=>3, :tc_is_first_token=>nil, :tc_token=>"Стерлитамакском", :tc_right_context=>"филиале", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>4, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Республиканский", :ne_right_context=>"фестиваль", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"РЕСПУБЛИКАНСКИЙ"}
# {:text_class_id=>5, :tc_is_first_token=>nil, :tc_token=>" Нефтекамске", :tc_right_context=>"сотрудник", :tc_left_context=>nil, :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>0, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Управление", :ne_right_context=>"собственной", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"УПРАВЛЕНИЕ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфе", :tc_right_context=>"по", :tc_left_context=>"в ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>true, :distance=>2, :tc_word_position=>true, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Средняя", :ne_right_context=>"цена", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"СРЕДНИЙ"}
# {:text_class_id=>4, :tc_is_first_token=>nil, :tc_token=>"Уфа", :tc_right_context=>nil, :tc_left_context=>"город ", :tc_quoted=>nil, :has_other_cities=>false, :in_one_sent=>false, :distance=>3, :tc_word_position=>false, :tc_same_as_feed=>true, :ne_is_first_token=>true, :ne_token=>"Специалистам", :ne_right_context=>"учреждений", :ne_left_context=>nil, :ne_quoted=>nil, :ne_lemma=>"СПЕЦИАЛИСТ"}










# 0.1
# {1=>{1=>92, -1=>8}, -1=>{-1=>73, 1=>27}}
# ["f-measure", 1, 0.8401826484018265]
# ["f-measure", -1, 0.8066298342541436]
# ["precision, recall", 1, 0.773109243697479, 0.92]
# ["precision, recall", -1, 0.9012345679012346, 0.73]
# ["accuracy", 0.825]
#  => ["accuracy", 0.825] 

# 1.0
# {1=>{1=>90, -1=>10}, -1=>{-1=>73, 1=>27}}
# ["f-measure", 1, 0.8294930875576038]
# ["f-measure", -1, 0.7978142076502732]
# ["precision, recall", 1, 0.7692307692307693, 0.9]
# ["precision, recall", -1, 0.8795180722891566, 0.73]
# ["accuracy", 0.815]
#  => ["accuracy", 0.815] 


# 1.0 - filtered test set
# {1=>{1=>67, -1=>5}, -1=>{-1=>56, 1=>14}}
# ["f-measure", 1, 0.8758169934640523]
# ["f-measure", -1, 0.8549618320610688]
# ["precision, recall", 1, 0.8271604938271605, 0.9305555555555556]
# ["precision, recall", -1, 0.9180327868852459, 0.8]
# ["accuracy", 0.8661971830985915]
#  => ["accuracy", 0.8661971830985915] 