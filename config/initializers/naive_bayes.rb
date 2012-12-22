#coding: utf-8
module NaiveBayes


	class NaiveBayes
    def get_features( string )
      #regexp = /[[:word:]]+{3,}/
      # (Ишим+[[:word:]]+|ИШИМ+[[:word:]]+|ишим+[[:word:]]+)
      regexp_ishimbay = /(Ишим+[[:word:]]+|ИШИМ+[[:word:]]+|ишим+[[:word:]]+)/   # Ишембай - bashkirian

      regexp_salavat = /(Салав+[[:word:]]+|САЛАВ+[[:word:]]+|салав+[[:word:]]+)/
      regexp_ufa = /(Уф+[[:word:]]+|УФ+[[:word:]]+|уфи+[[:word:]]+)/
      regexp_str = /(Стерл+[[:word:]]+|СТЕРЛ+[[:word:]]+|стерл+[[:word:]]+)/
      regexp_domain = /Domain:.+/
 	    features = [string.scan(regexp_str), string.scan(regexp_salavat), string.scan(regexp_ufa)].flatten.map{ |word| word.mb_chars.downcase.to_s }
      features.map!{|e| lemmatize(e)}.compact!
      features << string.scan(regexp_domain)[0].split("/")[2]
      features
    end


    def lemmatize word
      (`./lib/turglem-client #{word}`).split(" ")[1]
    end
  end



end