class Lemmatizer
  def self.lemmatize( token, quoted=false )
    return token if quoted
    
    lemmatized = []
    words = token.split(" ")
    words.each do |word|
      lemmatized << (`./lib/turglem-client #{word}`).split(" ")[1]
    end
    return lemmatized.join(" ")
  end
end