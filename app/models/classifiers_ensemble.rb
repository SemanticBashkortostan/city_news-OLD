class ClassifiersEnsemble

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