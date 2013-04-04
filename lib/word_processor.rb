class WordProcessor
  def self.lemmatize( token, quoted=false )
    return token if quoted
    
    lemmatized = []
    words = token.split(" ")
    words.each do |word|
      lemm_word = (`./lib/turglem-client #{word}`).split(" ")[1]
      lemm_word = word if lemm_word.blank?
      lemmatized << lemm_word
    end
    return lemmatized.join(" ")
  end


  def self.stem(feature, quoted)
    return feature if quoted
    stemmed = Lingua.stemmer( feature.split(" "), :language => :ru )
    return stemmed.join(" ") if stemmed.is_a?( Array )
    return stemmed
  end
end