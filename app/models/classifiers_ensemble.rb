class ClassifiersEnsemble


  def initialize classifiers, options={}
    @classifiers = classifiers
    if options[:preload] == true
      @classifiers.each{|cl| cl.preload_classifier}
    end
  end


  # Returns: {:class => klass_id, :recommend_as_train => trueORnil}
  # :recommend_as_train choose by find first entry with maximum :match_count
  # if his :recommend_as_train >= :not_recommend_to_train it will be :recommended_as_train
  def classify str
    multiplicator = 42
    classes_info = {}
    @classifiers.each do |classifier|
      cl_info = classifier.classify str
      klass = cl_info[:class]
      if cl_info
        classes_info[klass] ||= {:recommend_to_train => 0, :not_recommend_to_train => 0, :match_count => 0}
        classes_info[klass][:match_count] += 1
        if cl_info[:all_values][0] > (cl_info[:all_values][1] * multiplicator)
          classes_info[klass][:recommend_to_train] += 1
        else
          classes_info[klass][:not_recommend_to_train ] += 1
        end
      end
    end

    maybe_good = classes_info.max_by{|k, v| v[:match_count]}
    ret_info = { :class => maybe_good.first}
    if maybe_good[:recommend_to_train] >= maybe_good[:not_recommend_to_train]
      ret_info[:recommend_as_train] = true
    end
    return ret_info
  end


  def self.test_all( options={} )
    require 'csv'

    classifiers = Classifier.all
    classifiers.each{|cl| cl.preload_classifier}

    feeds_info = []
    Feed.tagged_with(Classifier::TRAIN_TAGS, :exclude => true).limit(100).each do |feed|
      feed_info = [ feed.id, feed.text_class.try(:name) ]
      classifiers.each do |classifier|
        classified = classifier.classify( feed.string_for_classifier )
        correct = (classified.nil? ? nil : (classified[:class] == feed.text_class.try(:id)))
        text_class_name = (classified.nil? ? nil : TextClass.find(classified[:class]).name)
        str = "(#{correct ? '+' : '-'})#{text_class_name}"
        feed_info << str
      end
      feed_info << feed.string_for_classifier[0..255]
      feeds_info << feed_info
    end

    column_names = ["feed_id", "feed.text_class"]
    classifiers.each{ |cl| column_names << cl.name }
    column_names << "str"
    CSV.open("#{Rails.root}/log/classifiers_ensemble_test.csv", "w") do |csv|
      csv << column_names
      feeds_info.each do |feed_info|
        csv << feed_info
      end
    end
  end


end