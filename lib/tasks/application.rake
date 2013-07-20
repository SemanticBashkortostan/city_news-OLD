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



  desc 'Add new city'
  task :add_new_city => :environment do
    add_new_city_metadata
    make_train_and_test_sets_for_new_city
    update_outlier_classifier
    make_classifier_for_new_city
  end


  def make_classifier_for_new_city
    text_class_name = "Октябрьский"
    tc = TextClass.find_by_name( text_class_name )

    classifier = Classifier.make_from_text_classes [tc], :name => Classifier::ROSE_NAIVE_BAYES_NAME + "-#{tc.eng_name}"
    classifier.test :feeds_count => 200, :is_random => true
  end


  def update_outlier_classifier
    outlier_nb = OutlierNb.new
    outlier_nb.preload
    outlier_nb.save(outlier_nb.filename + "-tmp-version-#{Time.now.strftime("%s")}")

    p "Outlier Nb performance before new learning"
    p outlier_nb.performance

    text_class_name = "Октябрьский"
    train_feeds = TextClass.find_by_name( text_class_name ).feeds
    train_feeds.each{ |feed| outlier_nb.train feed }

    p "Outlier Nb performance after new learning"
    p outlier_nb.performance

    outlier_nb.save
  end


  def make_train_and_test_sets_for_new_city
    text_class_name = "Октябрьский"
    tc = TextClass.find_by_name text_class_name

    feeds = Feed.tagged_with("outlier", :exclude => true).search( :title_or_summary_matches => 'Октябрьск' ).all
    start_feeds_count = feeds.count
    feeds.each do |feed|
      puts feed.string_for_classifier
      if STDIN.gets.chomp == 'd'
        feeds.delete(feed)
        puts "Deleted from feeds \n"
      end
    end
    p "#{start_feeds_count}/#{feeds.count}"

    feeds.each do |feed|
      feed.text_class.nil? ? feed.text_class = tc : feed.classified_infos.build( :text_class_id => tc.id )
      feed.save!
    end

    train_set, test_set = FeedsHelper.get_80_20( feeds.shuffle )
    train_set.each{|feed| feed.mark_list << "to_train"; feed.save!}
    test_set.each{|feed| feed.mark_list << "dev_test"; feed.save!}
  end


  def add_new_city_metadata
    text_class_name = "Октябрьский"
    tc = TextClass.create :name => text_class_name, :eng_name => "Oktyabrsky", :prepositional_name => "Октябрьского"

    ve = VocabularyEntry.new :token => text_class_name, :regexp_rule => "(Октябрьск*[[:word:]]+|ОКТЯБРЬСК*[[:word:]]+|октябрьск*[[:word:]]+|октябрьц*[[:word:]]+|октябрец*[[:word:]]+)",
                             :state => VocabularyEntry::ACCEPTED_STATE, :truly_city => true
    ve.text_classes << tc
    ve.save!

    oktyabrskii_bounding_box = {:top => 54.5055, :left => 53.4323, :bottom => 54.458, :right => 53.5439}
    okt_osm = FeatureFetcher::Osm.new(oktyabrskii_bounding_box, 'oktyabrsky.osm')
    okt_osm.get_part_of_map

    okt_dict = Dict.new.stem_dict okt_osm.get_features
    p "In Okt Dict: #{okt_dict.count}"
    okt_dict.each do |token|
      ve = VocabularyEntry.find_or_create_by_token_and_state token, VocabularyEntry::ACCEPTED_STATE
      ve.text_classes << tc
    end
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