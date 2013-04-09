#coding: utf-8

class Dict
  def initialize
    
  end


  def stem_dict_with_weights( features )
    stem_dict = {}
    stemmer= Lingua::Stemmer.new(:language => "ru")
    features.each do |feature_arr|
      feature = filter_for_weighted_stem feature_arr[0]
      stem_dict[feature] ||= {}
      stem_dict[feature][:weight] = stem_dict[feature][:weight].to_i + 1  
    end
    return stem_dict
  end


  # Return Set{ word1, word2 ... }
  def stem_dict( features )
    stem_dict = {}
    features.each do |feature_arr|
      feature, quoted = filter feature_arr[0]      
      if feature.is_a? Array 
        feature.each{ |f| stem_dict[feature] = {:stem => WordProcessor.stem(feature, quoted) } }
      else
        stem_dict[feature] = { :stem => WordProcessor.stem(feature, quoted) }
      end      
    end
    return dict_as_set(stem_dict, :stem)
  end


  def lemma_dict( features )
    lemma_dict = {}
    features.each do |feature_arr|
      feature, quoted = filter feature_arr[0]
      if feature.is_a? Array
        feature.each { |f| lemma_dict[feature] = {:lemma => WordProcessor.lemmatize( feature, quoted )} }
      else 
        lemma_dict[feature] = {:lemma => WordProcessor.lemmatize( feature, quoted )}
      end
    end
    return dict_as_set(lemma_dict, :lemma)
  end


  def dict_as_set raw_dict, key
    raw_dict.collect{|k,v| v[key]}.compact.to_set
  end


  def filter string
    big_words_regexp = /\b[А-ЯA-Z][[:word:]]*/
    quot_regexp = /&quot;(.*)&quot;/    
    token = ""
    quoteds = string.scan( quot_regexp )
    quoted = false
    if not quoteds.empty?      
      token = quoteds
      quoted = true
    else
      token = string.scan( big_words_regexp ).join(" ")
    end
    return [token, quoted]
  end


  def filter_for_weighted_stem( string )  
    words_regexp = /[[:word:]]+/ 
    stemmer= Lingua::Stemmer.new(:language => "ru")  
    string.scan( words_regexp ).map{|word| stemmer.stem( word )}.join(" ").mb_chars.downcase.to_s
  end
end
