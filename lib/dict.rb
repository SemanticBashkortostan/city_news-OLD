class Dict
  def initialize
    
  end


  def stem_dict_with_weights( features )
    stem_dict = {}
    stemmer= Lingua::Stemmer.new(:language => "ru")
    features.each do |feature_arr|
      feature = filter_string feature_arr[0]
      stem_dict[feature] ||= {}
      stem_dict[feature][:weight] = stem_dict[feature][:weight].to_i + 1  
    end
    return stem_dict
  end


  def filter_string( string )
    words_regexp = /[[:word:]]+/ 
    stemmer= Lingua::Stemmer.new(:language => "ru")  
    string.scan( words_regexp ).map{|word| stemmer.stem( word )}.join(" ").mb_chars.downcase.to_s
  end
end
