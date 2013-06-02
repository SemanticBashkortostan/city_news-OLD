#coding: utf-8

namespace :application do
  desc "Fully destroy old application state and make reloading WITHOUT destroying existing data"
  task :reload_state => :environment do
    TextClassFeature.destroy_all
    Rake::Task['bayes:init_train'].invoke
  end


  desc "Fill vocabulary( previously dict needs  )"
  task :fill_vocabulary => :environment do
    fill_vocabulary
  end


  desc "Make outlier svm classifier"
  task :make_outlier_svm_classifier => :environment do
    svm = OutlierSvm.new
    VocabularyEntry.testing_mode = 1
    svm.make_training_and_test_files
    svm.train_model :need_scaling => true, :need_optimizing => true
    VocabularyEntry.testing_mode = nil
  end


  desc "Make outlier ROSE-mnb classifier"
  task :make_outlier_rose_classifier => :environment do
    make_outlier_rose_classifier
  end


  desc "Make feeds cache"
  task :make_feeds_cache  => :environment do
    make_feeds_cache
  end


  desc "Make ROSE-MNB one vs all classifiers for each city"
  task :make_rose_mnb_classifiers => :environment do
    make_rose_mnb_classifiers
  end


  desc "Check fetched unclassified with outlier and testing mode"
  task :check_fetched_with_outlier => :environment do
    VocabularyEntry.testing_mode = 1
    onb = OutlierNb.new
    onb.preload
    onb.classify(Feed.unclassified_fetched.all)[:outlier].each do |feed|
      feed.mark_list = ["new_outlier"]
      feed.save!
    end
  end


  desc "Calculate peroformance for classifiers and write to file"
  task :calculate_classifiers_performances => :environment do
    file_prefix = "standard-rmnb-350"
    Classifier.all.each do |cl|
      if cl.is_rose_naive_bayes?  && !cl.name["with-exec-re"]
        cl.preload_classifier
        cl.test :feeds_count => 350, :tags => Classifier::TRAIN_TAGS,
                :tags_options => { :exclude => true }, :file_prefix => file_prefix
      end
    end
  end


  desc 'Updated to new version'
  task :update_to_new_version => :environment do

    puts "Making osm maps"
    FeatureFetcher::Osm.make_maps_from_text_classes
    puts "Making stem dicts"
    Dict.get_stem_dicts
    puts "Filling vocabulary"
    fill_vocabulary
    puts "Making feeds cache"
    make_feeds_cache
    puts "Making outlier rose classifier"
    make_outlier_rose_classifier
    puts "Making ROSE classifiers"
    make_rose_mnb_classifiers
    puts "Making relation extractor"
    make_relation_extractor

    puts "Calculating performance"
    calculate_all_performances( "1init_osm_" )


    puts "Extracting new words and filling vocabulary using relation extractor"
    extract_new_words_and_fill_vocabulary

    puts "Using new extracted words"
    VocabularyEntry.testing_mode = 1
    puts "Making new OUTLIER rose classifiers with extracted words"
    make_outlier_rose_classifier
    puts "Making rose classifiers with new words"
    make_rose_mnb_classifiers( "-with-exec-re" )

    puts "Calculating new performance"
    calculate_all_performances( "2using_re_" )
  end


  def extract_new_words_and_fill_vocabulary
    re = RelationExtractor.new true
    re.iteratively_extract_patterns
    re.extract_new_words_and_fill_vocabulary!
  end


  def calculate_all_performances( file_prefix )
    Classifier.all.each do |cl|
      if cl.is_rose_naive_bayes?
        cl.preload_classifier
        cl.test :feeds_count=>500, :tags=>["fetched", "classified", "production"],
                :tags_options=>{ :match_all => true }, :file_prefix => file_prefix
      end
    end

    onb_and_re_test_info = ""
    onb = OutlierNb.new
    onb.preload
    onb_and_re_test_info << "#{file_prefix} ONB-performance #{onb.performance}\n"

    re = RelationExtractor.new true
    re_performance = re.patterns_hash_file_exist? ? re.performance( re.patterns_hash_file ) : re.performance
    onb_and_re_test_info << "#{file_prefix} RE-performance #{re_performance}\n"

    File.new("#{Rails.root}/log/#{file_prefix}-onb_and_re_test.log", 'w').write(onb_and_re_test_info)
  end


  def make_rose_mnb_classifiers( additional_name = "")
    TextClass.all.each do |tc|
      Classifier.make_from_text_classes [tc], :name => "#{Classifier::ROSE_NAIVE_BAYES_NAME}-#{tc.eng_name}#{additional_name}"
    end
  end


  def make_outlier_rose_classifier
    onb = OutlierNb.new
    onb.make_classifier
  end


  def make_feeds_cache
    Feed.cached :recreate => true
    Feed.cached :filename => 'outlier_cached', :recreate => true, :feeds => Feed.tagged_with("outlier").all, :need_re => false
  end


  def make_relation_extractor
    re = RelationExtractor.new true
    re.iteratively_extract_patterns
  end


  def fill_vocabulary
    filename = "#{Rails.root}/project_files/stem_vocabulary_hash"
    raise Exception unless File.exist?(filename)
    text_class_vocabulary = Marshal.load( File.binread(filename) )
    text_class_vocabulary.each do |text_class_id, vocabulary|
      vocabulary.each do |token|
        ve = VocabularyEntry.find_or_create_by_token_and_state token, VocabularyEntry::ACCEPTED_STATE
        ve.text_class_ids = text_class_id
        ve.save
      end
    end

    # Initial filling VocabularyEntry rules
    Settings.bayes.regexp.downcased.each do |text_class_name, regexp|
      ve = VocabularyEntry.find_or_create_by_token_and_regexp_rule_and_state text_class_name, regexp, VocabularyEntry::ACCEPTED_STATE
      ve.text_classes << TextClass.find_by_name(text_class_name)
      ve.save!(:validate => false)
    end
    #NOTE: Maybe use only Feed#domain instead of applying domain rule in VocabularyEntry
    ve = VocabularyEntry.new :regexp_rule => Settings.bayes.regexp.domain, :state => VocabularyEntry::ACCEPTED_STATE
    ve.save!(:validate => false)

    Settings.bayes.regexp.truly_cities.each do |text_class_name, regexp|
      ve = VocabularyEntry.find_or_create_by_token_and_regexp_rule_and_state_and_truly_city text_class_name, regexp, VocabularyEntry::ACCEPTED_STATE, true
      ve.text_classes << TextClass.find_by_name(text_class_name)
      ve.save!(:validate => false)
    end
  end
end