#coding: utf-8

class RelationExtractor

  include Statistic

  attr_reader :positive_train_set, :positive_test_set, :maybe_negative_set

  def initialize( need_preload = false )
    @patterns_filename = "#{Rails.root}/project_files/classifiers/relation_extractor/patterns_hash"
    @path = @patterns_filename.split("/")[0...-1].join("/")
    FileUtils.mkdir_p(@path) unless File.exists?(@path)
    preload if need_preload
  end


  # Generalize pattern from Feed#feature_vectors_for_relation_extraction
  def filter_features_in init_example, train=false
    example = init_example.clone
    ending_keys = [ :tc_right_context, :tc_left_context, :ne_right_context, :ne_left_context]
    other_keys = [ :tc_is_first_token, :in_one_sent,
                   :tc_word_position, :tc_same_as_feed, :ne_is_first_token ]
    if (example[:ne_right_context] || example[:ne_left_context]) && (example[:tc_right_context] || example[:tc_left_context])
      example.keys.each do |key|
        if ending_keys.include?(key) && example[key]
          if example[key].length > 3
            example[key] = example[key][-3..-1]
          else
            example[key] = example[key][-1]
          end
        elsif !(other_keys.include?(key))
          example[key] = nil
        end
      end
      return example
    else
      return nil
    end
  end


  def patterns_hash_file
    FileMarshaling.marshal_load @patterns_filename
  end


  def patterns_hash_file_exist?
    File.exist? @patterns_filename
  end


  # Get generalized patterns from set of feed.feature_vectors_for_relation_extraction
  def get_generalized_patterns set=nil
    dipre_hash = {}
    set ||= @positive_train_set

    set.each_with_index do |(example, example_id), i|
      puts "Processed: #{i}/#{set.count}"
      filtered_example = filter_features_in(example)
      dipre_hash[filtered_example] = dipre_hash[filtered_example].to_i + 1 if filtered_example
    end

    patterns = Hash[dipre_hash.find_all{|generalized_pattern, seen_count| seen_count > 2}]
    return patterns
  end


  # Extract new dict from given set of feature vectors and patterns
  def extract_new_dict( set, patterns_hash )
    new_dict = {}
    set.each do |(example, id)|
      filtered_example = filter_features_in(example)
      if filtered_example
        new_dict[example[:text_class_id]] ||= Set.new
        new_dict[example[:text_class_id]] += [example[:ne_stem], example[:tc_stem]] if patterns_hash[filtered_example]
      end
    end
    return new_dict
  end


  # 1. Find or set patterns from given feature vectors, 2. get new feature vectors from patterns,
  # 3. return to 1 with new feature vectors
  # It saves all patterns into @patterns_filename
  def iteratively_extract_patterns( from_file = false, patterns_hash = nil )
    from_file ? patterns_hash ||= FileMarshaling.marshal_load( @patterns_filename ) : patterns_hash ||= get_generalized_patterns( @positive_train_set )

    loop do
      init_count = patterns_hash.count

      new_dict = extract_new_dict(@maybe_negative_set, patterns_hash)
      new_vectors = extract_vectors_for_relation_extractor( new_dict )[0]

      patterns_hash.merge!( get_generalized_patterns(new_vectors) )
      puts "Old Count: #{init_count} New Count: #{patterns_hash.count}"

      break if init_count == patterns_hash.count
    end
    p performance(patterns_hash)
    FileMarshaling.marshal_save @patterns_filename, patterns_hash
    return patterns_hash
  end


  # Get new words and fill vocabulary using patterns_hash from @patterns_filename
  # First you need to create patterns_hash. It can be done with +iteratively_extract_patterns+
  def extract_new_words_and_fill_vocabulary!
    patterns_hash = FileMarshaling.marshal_load @patterns_filename
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


  def preload
    load_test_sets
    load_train_sets
    @positive_train_set -= @positive_test_set
    @maybe_negative_set -= @negative_test_set
    @maybe_negative_set -= @positive_test_set
  end


  def load_test_sets
    test_positive_filename = "#{@path}/positive_re_test_set-new"
    test_negative_filename = "#{@path}/negative_re_test_set-new"
    @positive_test_set = FileMarshaling.marshal_load test_positive_filename
    @negative_test_set = FileMarshaling.marshal_load test_negative_filename
  end


  def load_train_sets
    pos_and_neg_sets = extract_vectors_for_relation_extractor
    @positive_train_set = pos_and_neg_sets[0]
    @maybe_negative_set = pos_and_neg_sets[1]
  end


  def performance( patterns_hash = nil )
    confusion_matrix = { 1 => { 1=>0, -1 => 0}, -1 => {1=>0, -1=>0} }
    patterns_hash ||= get_generalized_patterns
    @positive_test_set.each do |(example, id)|
      filtered_example = filter_features_in(example , false)
      if patterns_hash[filtered_example]
        confusion_matrix[1][1] += 1
      else
        confusion_matrix[1][-1] += 1
      end
    end

    @negative_test_set.each do |(example, id)|
      filtered_example = filter_features_in(example , false)
      if patterns_hash[filtered_example]
        confusion_matrix[-1][1] += 1
        p [example, filtered_example, "-1 1"]
      else
        confusion_matrix[-1][-1] += 1
      end
    end

    return {
             :confusion_matrix => confusion_matrix, :accuracy => accuracy(confusion_matrix),
             :f_measure_city => f_measure(confusion_matrix, 1), :f_measure_outlier => f_measure(confusion_matrix, -1)
           }
  end


  protected


  def generate_dict_from_vocabulary_entry
    dict = {}
    TextClass.all.each do |text_class|
      dict[text_class.id] = VocabularyEntry.for_city(text_class.id).collect(&:token).to_set
    end
    return dict
  end


  def generate_truly_rules_from_vocabulary_entry
    truly_rules = {}
    TextClass.all.each do |text_class|
      truly_rules[text_class.id] = Regexp.new(VocabularyEntry.make_regexp_for_truly_entries(text_class.id)[0])
    end
    return truly_rules
  end


  def get_feeds
    Feed.cached
  end


  # Return [positive_set, maybe_negative_set]; Positive set forming by check( text class token is true text class) and (named entity is on dict)
  def extract_vectors_for_relation_extractor(dict = nil)
     positive_set = []
     maybe_negative_set = []
     dict ||= generate_dict_from_vocabulary_entry
     truly_rules = generate_truly_rules_from_vocabulary_entry
     feeds = get_feeds
     text_classes = TextClass.all
     feeds.each_with_index do |feed, ind|
       p "proccesed #{feed.id} :: #{ind}/#{feeds.count}"
       feed_feature_vectors = feed.feature_vectors_for_relation_extraction
       next unless feed_feature_vectors
       feed_feature_vectors.each { |fv|
         text_classes.each do |tc|
           tc_id = tc.id
           if fv[:tc_stem] =~ truly_rules[tc_id] && fv[:tc_stem] != fv[:ne_stem] && fv[:ne_stem].length > 1
             city_dictionary = dict[tc_id]
             if city_dictionary.include?(fv[:ne_stem])
               positive_set << [fv, feed.id]
               break
             else
               maybe_negative_set << [fv, feed.id]
               break
             end
           end
         end
       }
     end
     return [positive_set, maybe_negative_set]
   end


  # count=51
  # Only Named Entities
  # Interactively creating test sets( needs only for development )
  def form_sets
    positive_filename = "#{@path}/positive_re_set-new"
    positive_set = load_set positive_filename

    negative_filename = "#{@path}/negative_re_set-new"
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