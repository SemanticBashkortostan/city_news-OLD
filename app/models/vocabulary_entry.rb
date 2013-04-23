class VocabularyEntry < ActiveRecord::Base  

  # Regexp rule may have mapping to token
  attr_accessible :regexp_rule, :state, :token


  ACCEPTED_STATE = 10
  DECLINED_STATE = 20
  TESTING_STATE  = 30
  NOT_IN_VOCABULARY_STATE = 40


  has_and_belongs_to_many :text_classes


  scope :rules, where('regexp_rule is NOT NULL')


  state_machine :state, :initial => :testing do
    state :accepted, :value => ACCEPTED_STATE
    state :declined, :value => DECLINED_STATE
    state :testing, :value => TESTING_STATE
    state :not_in_vocabulary, :value => NOT_IN_VOCABULARY_STATE
  end
  scope :accepted, with_state( :accepted )


  def self.has?( string, is_rule = nil )
    scope = VocabularyEntry.accepted
  	found = scope.find_by_token( string )
    return found if found

    rule_features = []
    if is_rule
      scope.rules.each do |rule|
        if string =~ Regexp.new(rule.regexp_rule)
          ret_val = rule.token
          ret_val ||= string.scan(Regexp.new(rule.regexp_rule)).first
          rule_features << ret_val
        end
      end
    end
    return nil if rule_features.blank?
    return rule_features
  end


  def self.words_matches_rules(string)
    VocabularyEntry.has?(string, true)
  end


end
