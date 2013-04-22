class VocabularyEntry < ActiveRecord::Base  

  # Regexp rule may have mapping to token
  attr_accessible :regexp_rule, :state, :token


  ACCEPTED_STATE = 10
  DECLINED_STATE = 20
  TESTING_STATE  = 30
  NOT_IN_VOCABULARY_STATE = 40


  has_and_belongs_to_many :text_classes


  scope :accepted, where(:state => ACCEPTED_STATE)
  scope :rules, where('regexp_rule is NOT NULL')


  state_machine :state, :initial => :testing do
    state :accepted, :value => ACCEPTED_STATE
    state :declined, :value => DECLINED_STATE
    state :testing, :value => TESTING_STATE
    state :not_in_vocabulary, :value => NOT_IN_VOCABULARY_STATE
  end


  def self.has?( string, is_rule = nil )
    scope = VocabularyEntry.accepted
  	found = scope.find_by_token( string )
    return found if found    
    if is_rule
      scope.rules.each do |rule|
        return (rule.token || string) if string =~ Regexp.new(rule.regexp_rule)
      end
    end  	
  end


end
