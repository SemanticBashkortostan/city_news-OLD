module FeedsHelper
  def get_train_and_test_feeds type, from_cache=nil
    from_cache ||= @from_cache
    if from_cache
      case type
        when :city
          feeds = Feed.cached
          [
              feeds.find_all { |feed| feed.mark_list.include?("dev_train") || feed.mark_list.include?("to_train") || feed.mark_list.include?("was_trainer") },
              feeds.find_all { |feed| feed.mark_list.include?("dev_test") || (feed.mark_list - ["fetched", "production", "classified"]).empty? }
          ]
        when :outlier
          Feed.cached(:filename => 'outlier_cached').to_a.shuffle
      end
    else
      case type
        when :city
          [
              Feed.tagged_with(["dev_train", "to_train", "was_trainer"], :any => true).where(:text_class_id => TextClass.all),
              Feed.tagged_with(["dev_test"], :any => true).where(:text_class_id => TextClass.all) +
                  Feed.tagged_with(["fetched", "production", "classified"], :match_all => true).where(:text_class_id => TextClass.all)
          ]
        when :outlier
          Feed.tagged_with("outlier").all.shuffle
      end
    end

  end
end
