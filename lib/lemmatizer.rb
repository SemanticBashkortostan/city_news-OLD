class Lemmatizer
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
end