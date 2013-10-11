class TuneFuzzyTextMatch
  def initialize
    @result_file = File.open('fuzzy_text_match.txt', 'w')
    @feeds = Feed.tagged_with( "near_duplicate_test" ).all
    @test_set_filename = 'fuzzy_text_match_test_set'
  end


  def accuracy
    pretty_result = {}
    for i in 0...feeds.count
      for j in (i+1)...feeds.count
        next if feeds[i].nil? || feeds[j].nil?
        score = feeds[i].similarity(feeds[j])
        pretty_result[feeds[i].id] ||= {:title => feeds[i].title, :similars => []}
        if score > 0.4
          pretty_result[feeds[i].id][:similars] << [feeds[j].id, feeds[j].title, score]
          feeds[j] = nil
        end
      end
    end
    groups = pretty_result.map{|k,v| [k, v[:similars].collect{ |arr| arr[0] }].flatten }
    test_groups = FileMarshaling.marshal_load(@test_set_filename).map{ |k,v| v.collect{|feed| feed.id} }

    result = {}
    test_groups.each_with_index do |test_group, ind|
      groups.each do |group|
        accuracy = test_group.to_set.intersection(group).count / test_group.count.to_f
        result[ind] = accuracy if result[ind].nil? || accuracy > result[ind]
      end
    end
    p result.values.sum / result.values.count
    result
  end


  def feeds
    @feeds.dup
  end


  def form_test_set
    feeds.each do |feed|
      puts "#{feed.id}, #{feed.title}"
    end

    @test_set = {}
    feeds.each do |feed|
      puts "#{feed.id}, #{feed.title}"
      group_num = gets.chomp
      @test_set[group_num] ||= []
      @test_set[group_num] << feed
    end

    FileMarshaling.marshal_save @test_set_filename, @test_set
  end
end