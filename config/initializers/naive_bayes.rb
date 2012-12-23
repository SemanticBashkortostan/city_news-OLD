#coding: utf-8
module NaiveBayes


	class NaiveBayes
    def get_features( string )
      features = []
      Settings.bayes.shorten_klasses.each do |short_name|
        regexp_hash = { :regexp => Regexp.new( Settings.bayes.regexp[short_name][0] ), :name => Settings.bayes.regexp[short_name][1] }
        feature = scan( string, regexp_hash  )
        features << feature if feature
      end
      features << string.scan( Regexp.new( Settings.bayes.regexp["domain"][0] ) )[0].split("/")[2]
      features
    end


    def lemmatize word
      (`./lib/turglem-client #{word}`).split(" ")[1]
    end


    def scan string, regexp_hash
      regexp_hash[:name] unless string.scan( regexp_hash[:regexp] ).empty?
    end
  end



end