require 'spec_helper'

describe Classifier do

  module NaiveBayes
  	class NaiveBayes
      def get_features( string )
        string.split(" ")
      end
    end
  end


  def initialize_two_klass_case
    @train_data = [
                              ["Chinese Beijing Chinese", :c],
                              ["Chinese Chinese Shanghai", :c],
                              ["Chinese Macao", :c],
                              ["Tokyo Japan Chinese", :j]
                        ]
    @features = @train_data.collect{|e| e.first.split(" ")}.flatten.uniq.sort
    @test_data = ["Chinese Chinese Chinese Tokyo Japan"]

    @text_class1 = TextClass.create! :name => :c
    @text_class2 = TextClass.create! :name => :j
  end


  def initialize_three_klass_case
    @train_data1 = [
                        ["Chinese Beijing Chinese", :c],
                        ["Chinese Chinese Shanghai", :c],
                        ["Chinese Macao", :c],
                        ["Tokyo Japan Chinese", :j]
                   ]

    @train_data2 = [
                        ["Chinese Beijing Chinese", :c],
                        ["Chinese Chinese Shanghai", :c],
                        ["Chinese Macao", :c],
                        ["Chinese Macao", :c],
                        ["Tokyo Japan Chinese", :j],
                        ["Chinese Tokyo Japan Aizu", :j],
                        ["Moscow Ufa Tokyo", :r]
                   ]
    @features = (@train_data1 + @train_data2).collect{|e| e.first.split(" ")}.flatten.uniq.sort
    @test_data = ["Chinese Chinese Chinese Tokyo Japan"]

    @text_class1 = TextClass.create! :name => :c
    @text_class2 = TextClass.create! :name => :j
    @text_class3 = TextClass.create! :name => :r
  end


  def convert_train_data_to_feed train_data
    train_data.each do |(str , klass)|
       Feed.create! :summary => str, :text_class_id => TextClass.find_by_name(klass).id, :url => "url#{str.object_id}", :mark_list => ["test_train"]
     end
  end
  #
  #
  #context "NaiveBayes" do
  #
  #  before :each do
  #    initialize_two_klass_case
  #    #NOTE: Проверь, если .new вместо .create
  #    @name = Classifier::NAIVE_BAYES_NAME
  #    @classifier_nb1 = Classifier.create! :name => @name
  #  end
  #
  #
  #  it "should correctly insert features and feature properties for classifier" do
  #    TextClassFeature.all.should be_empty
  #
  #    @classifier_nb1.preload_classifier
  #    @train_data.each do |(str, klass)|
  #      @classifier_nb1.train(str, klass)
  #    end
  #    @classifier_nb1.save_to_database!
  #
  #    Feature.uniq.pluck(:token).sort.should == @features
  #
  #    @classifier_nb1.text_class_features.collect{|e| e.id}.sort.should == TextClassFeature.pluck(:id).sort
  #
  #    tcf = TextClassFeature.find_by_text_class_id_and_feature_id( TextClass.find_by_name(:c), Feature.find_by_token("Chinese").id )
  #    ClassifierTextClassFeatureProperty.find_by_text_class_feature_id_and_classifier_id( tcf.id, @classifier_nb1.id ).feature_count.should == 5
  #  end
  #
  #
  #  it "should correctly classify test example and load all database dependences" do
  #    TextClassFeature.all.should be_empty
  #
  #    @classifier_nb1.preload_classifier
  #    @train_data.each do |(str, klass)|
  #      @classifier_nb1.train(str, klass)
  #    end
  #    @classifier_nb1.save_to_database!
  #
  #    @classifier_nb1 = Classifier.find_by_name @name
  #
  #    expect{ @classifier_nb1.classify( @test_data[0] ) }.to raise_error
  #
  #    @classifier_nb1.preload_classifier( {:docs_count => {TextClass.find_by_name(:c).id => 3, TextClass.find_by_name(:j).id => 1} } )
  #    @classifier_nb1.classify( @test_data[0] )[:class].should == TextClass.find_by_name(:c).id
  #  end
  #
  #end
  #
  #
  #context "SeveralClassifiers" do
  #
  #  before :each do
  #    initialize_three_klass_case
  #    #NOTE: Проверь, если .new вместо .create
  #    @name1 = Classifier::NAIVE_BAYES_NAME
  #    @name2 = Classifier::NAIVE_BAYES_NAME + "-2"
  #    @classifier_nb1 = Classifier.create! :name => @name1
  #    @classifier_nb2 = Classifier.create! :name => @name2
  #  end
  #
  #  it "should divide classifiers data in database" do
  #    @classifier_nb1.preload_classifier
  #    @train_data1.each do |(str, klass)|
  #      @classifier_nb1.train(str, klass)
  #    end
  #    @classifier_nb1.save_to_database!
  #
  #    @classifier_nb2.preload_classifier
  #    @train_data2.each do |(str, klass)|
  #      @classifier_nb2.train(str, klass)
  #    end
  #    @classifier_nb2.save_to_database!
  #
  #    Feature.uniq.pluck(:token).sort.should == @features
  #
  #    @classifier_nb1.text_class_features.collect{|e| e.id}.sort.should_not == TextClassFeature.pluck(:id).sort
  #
  #    tcf = TextClassFeature.find_by_text_class_id_and_feature_id( TextClass.find_by_name(:c), Feature.find_by_token("Chinese").id )
  #    ClassifierTextClassFeatureProperty.find_by_text_class_feature_id_and_classifier_id( tcf.id, @classifier_nb1.id ).feature_count.should == 5
  #    ClassifierTextClassFeatureProperty.find_by_text_class_feature_id_and_classifier_id( tcf.id, @classifier_nb2.id ).feature_count.should == 6
  #
  #    r_klass = TextClass.find_by_name( :r )
  #    @classifier_nb1.text_classes.should_not include( r_klass )
  #    @classifier_nb2.text_classes.should include( r_klass )
  #
  #    @classifier_nb1.reload
  #    nb_data = ClassifierTextClassFeatureProperty.import_to_naive_bayes( @classifier_nb1 )
  #    nb_data[:docs_count].keys.should_not include(r_klass.id)
  #
  #    nb_data = ClassifierTextClassFeatureProperty.import_to_naive_bayes( @classifier_nb2 )
  #    nb_data[:docs_count].keys.should include(r_klass.id)
  #  end
  #end
  #
  #
  #context "Work with Classifier's klasses" do
  #  context "ClassExtraction" do
  #
  #    it "should extract text_class from classifier and rebuild it" do
  #      initialize_three_klass_case
  #      convert_train_data_to_feed( @train_data2 )
  #      classifier = Classifier.make_from_text_classes( [ @text_class1, @text_class2, @text_class3 ], :name => Classifier::NAIVE_BAYES_NAME )
  #      classifier.extract_class!( @text_class3 )
  #      classifier.text_classes.all.should == [@text_class1, @text_class2]
  #      classifier.text_class_features.where( :text_class_id => @text_class3 ).should be_empty
  #      TextClassFeature.where( :text_class_id => @text_class3 ).should_not be_empty
  #    end
  #
  #
  #    it "should make new Classifier from extracted klass" do
  #
  #    end
  #
  #  end
  #
  #
  #  context "TextClass" do
  #
  #    it "should show that TextClass has require data" do
  #      pending
  #    end
  #
  #
  #    it "should make Classifier from TextClasses" do
  #      initialize_two_klass_case
  #      convert_train_data_to_feed @train_data
  #
  #      Classifier.make_from_text_classes( [ @text_class1, @text_class2 ], :name => Classifier::NAIVE_BAYES_NAME )
  #      Classifier.count.should == 1
  #      classifier = Classifier.first
  #      classifier.preload_classifier
  #      classifier.classify( @test_data[0] )[:class].should == TextClass.find_by_name(:c).id
  #    end
  #  end
  #
  #
  #end
  #
  
  context "Performance of Classifier" do
    it "should correctly calculate performance of the classifier" do
      initialize_two_klass_case
      @train_data += [["Tokyo Japan Kioto", :j], ["Aizu", :j]]
      convert_train_data_to_feed @train_data
      Feed.create! :summary => "Tokyo", :text_class_id => TextClass.last.id, :url => "dsa#2", :mark_list => ["dev_test"]
      Feed.create! :summary => "Chinese", :text_class_id => TextClass.first.id, :url => "dsda#2", :mark_list => ["dev_test"]

      classifier = Classifier.make_from_text_classes([@text_class1, @text_class2], :name => Classifier::NAIVE_BAYES_NAME)
      classifier.test
    end
  end


end
