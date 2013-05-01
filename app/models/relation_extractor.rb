#coding: utf-8

class RelationExtractor
  def initialize
    load_test_and_training_sets
  end


  def filter_features_in example, train=false
    ending_keys = [ :tc_right_context, :tc_left_context, :ne_right_context, :ne_left_context]
    other_keys = [ :tc_is_first_token, :has_other_cities, :in_one_sent,
                   :tc_word_position, :tc_same_as_feed, :ne_is_first_token ]
    if(example[:ne_right_context] || example[:ne_left_context])
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


  def get_generalized_patterns set=nil
    dipre_hash = {}
    set ||= @positive_train_set

    set.each_with_index do |(example, example_id), i|
      filter_features_in(example, true)
      dipre_hash[example] = dipre_hash[example].to_i + 1
    end

    patterns = Hash[dipre_hash.find_all{|k,v| v > 1}]
    return patterns
  end


  def test( patterns_hash = nil )
    confusion_matrix = { 1 => { 1=>0, 0 => 0}, 0 => {1=>0, 0=>0} }
    patterns_hash ||= get_generalized_patterns
    @positive_test_set.each do |(example, id)|
      filter_features_in(example, false)
      if patterns_hash[example]
        confusion_matrix[1][1] += 1
      else
        confusion_matrix[1][0] += 1
      end
    end

    @negative_test_set.each do |(example, id)|
      if patterns_hash[example]
        confusion_matrix[0][1] += 1
      else
        confusion_matrix[0][0] += 1
      end
    end

    p confusion_matrix
  end


  def extract_new_dict( set, patterns_hash )
    new_dict = {}
    set.each do |(example, id)|
      to_apply_example = example.clone
      filter_features_in(to_apply_example)
      new_dict[example[:text_class_id]] ||= Set.new
      new_dict[example[:text_class_id]] += [example[:ne_stem], example[:tc_stem]] if patterns_hash[to_apply_example]
    end
    return new_dict
  end


  # Находим слова и ищем фиды с этими словами, потом опять генерелизуем паттерны, пока находятся слова.
  def iteratively_extract_patterns
    patterns_hash = get_generalized_patterns( @positive_train_set )
    ff_relation_extractor = FeatureFetcher::RelationExtractor.new
    ff_relation_extractor.preload_feeds_data

    loop do
      init_count = patterns_hash.count

      new_dict = extract_new_dict(@maybe_negative_set, patterns_hash)
      new_vectors = ff_relation_extractor.extract_vectors_for_relation_extractor( new_dict )

      patterns_hash.merge!( get_generalized_patterns(new_vectors) )
      puts "Old Count: #{init_count} New Count: #{patterns_hash.count}"

      break if init_count == patterns_hash.count
    end
    test(patterns_hash)
    save_set "patterns_hash", patterns_hash
    return patterns_hash
  end


  # TODO: TEST WITH NEW DATA!!!
  def dev_extract_new_words
    patterns_hash = load_set("patterns_hash", true)
    new_dict = extract_new_dict( @maybe_negative_set, patterns_hash)
    new_dict.each do |tc_id, tc_dict|
      tc_dict.each do |word|
        ve = VocabularyEntry.new :token => word, :state => VocabularyEntry::TESTING_STATE
        ve.text_classes << TextClass.find(tc_id)
        ve.save
      end
    end
    puts "#{VocabularyEntry.accepted.only_tokens.count} / #{VocabularyEntry.unscoped.with_state(:testing).only_tokens.count}"
  end


  protected


  def load_test_and_training_sets
    load_test_sets
    load_train_sets
  end


  def load_test_sets
    test_positive_filename = "positive_re_test_set-new"
    test_negative_filename = "negative_re_test_set-new"
    @positive_test_set = load_set test_positive_filename
    @negative_test_set = load_set test_negative_filename
  end


  def load_train_sets
    positive_filename = "positive_re_set-new"
    @positive_train_set = load_set positive_filename

    negative_filename = "negative_re_set-new"
    @maybe_negative_set = load_set negative_filename
  end


  def load_set filename, only_load=false
    loaded_hash = Marshal.load(File.binread(filename))
    return loaded_hash if only_load || !loaded_hash.is_a?( Hash )
    return loaded_hash.values.to_a.flatten if loaded_hash.is_a?( Hash )
  end


  def save_set filename, set
    File.open(filename,'wb') do |f|
      f.write Marshal.dump(set)
    end
  end


  # count=51
  # Only Named Entities
  def form_sets
    positive_filename = "positive_re_set-new"
    positive_set = load_set positive_filename

    negative_filename = "negative_re_set-new"
    negative_set = load_set negative_filename

    positive_test_set = []
    positive_set.shuffle.each do |positive_example|
      puts positive_example
      puts "In positive test set: #{positive_test_set.count}"
      puts "Type 'y' if true positive and 'f' in other case"
      key = gets.chomp
      positive_test_set << positive_example if key == 'y'
      break if key == 's'
    end

    negative_test_set = []
    negative_set.shuffle.each do |example|
      puts example
      puts "In negative test set: #{negative_test_set.count}"
      puts "Type 'y' if true negative and 'f' in other case"
      key = gets.chomp
      negative_test_set << example if key == 'y'
      break if key == 's'
    end

    test_positive_filename = "positive_re_test_set-new"
    test_negative_filename = "negative_re_test_set-new"
    save_set test_positive_filename , positive_test_set
    save_set test_negative_filename, negative_test_set
  end
end