#coding: utf-8
module NaiveBayes


	class NaiveBayes
    def get_features( string )
      #regexp = /[[:word:]]+{3,}/
      # (Ишим+[[:word:]]+|ИШИМ+[[:word:]]+|ишим+[[:word:]]+)
      regexp_ishimbay = /(Ишим+[[:word:]]+|ИШИМ+[[:word:]]+|ишим+[[:word:]]+)/   # Ишембай - bashkirian

      regexp_salavat = {:regexp => /(Салав+[[:word:]]+|САЛАВ+[[:word:]]+|салав+[[:word:]]+)/, :name => "Салават"}
      regexp_ufa = {:regexp => /(Уф+[[:word:]]+|УФ+[[:word:]]+|уфи+[[:word:]]+)/, :name => "Уфа"}
      regexp_str = {:regexp => /(Стерл+[[:word:]]+|СТЕРЛ+[[:word:]]+|стерл+[[:word:]]+)/, :name => "Стерлитамак"}
      regexp_domain = /Domain:.+/
 	    features = [scan(string, regexp_str), scan(string, regexp_salavat), scan(string, regexp_ufa)].compact.map{ |word| word.mb_chars.downcase.to_s }
      features << string.scan(regexp_domain)[0].split("/")[2]
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