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
 	    [string.scan(regexp_str), string.scan(regexp_salavat), string.scan(regexp_ufa)].flatten

      #[string.scan(regexp_str), string.scan(regexp_salavat), string.scan(regexp_ufa), string.scan(regexp_ishimbay)].flatten
 	  end
  end


end