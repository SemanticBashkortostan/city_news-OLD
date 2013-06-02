#
# CityNews - news aggregator software
# Copyright (C) 2013  Idris Yusupov
#
# This file is part of CityNews.
#
# CityNews is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# CityNews is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with CityNews.  If not, see <http://www.gnu.org/licenses/>.
#
class VocabularyEntry < ActiveRecord::Base  

  # Regexp rule may have mapping to token
  attr_accessible :regexp_rule, :state, :token

  cattr_accessor :testing_mode

  ACCEPTED_STATE = 10
  DECLINED_STATE = 20
  TESTING_STATE  = 30
  NOT_IN_VOCABULARY_STATE = 40


  validate :truly_rule_validation
  validate :token_uniqueness_for_tokens_only


  has_and_belongs_to_many :text_classes, :uniq => true


  state_machine :state, :initial => :testing do
    state :accepted, :value => ACCEPTED_STATE
    state :declined, :value => DECLINED_STATE
    state :testing, :value => TESTING_STATE
    state :not_in_vocabulary, :value => NOT_IN_VOCABULARY_STATE
  end

  scope :accepted, with_state( :accepted )

  def self.default_scope
    (VocabularyEntry.testing_mode == 1) ? with_state(:accepted, :testing) : with_state(:accepted)
  end

  #NOTE: If regexp_rule contains '\' like '\d' then need adding escape for '\' like '\\d'
  #NOTE: Standard rules can applied into any token, Truly rules applied only for one-word token
  #NOTE: truly_city now can be nil and its not good, `!= 't'` not give values where `is NULL`
  scope :standard_rules, where('regexp_rule is not ? and (truly_city != ? or truly_city IS NULL)', nil, true)
  #NOTE: Each truly rule for one text class should map in 1 token and truly rule has only 1 text_class
  scope :truly, where('truly_city = ?', true)
  scope :for_city, lambda{ |tc_id| includes(:text_classes).where(:text_classes => { :id =>  tc_id} ) }
  scope :for_cities_other_than, lambda{ |tc_id| includes(:text_classes).where( 'text_classes_vocabulary_entries.text_class_id != ?', tc_id ) }
  scope :only_tokens, where('regexp_rule is ? AND token is not ?', nil, nil)



  def self.has?( string, options={} )
    VocabularyEntry.find_by_token( string )
  end


  # Returns truly_rule mapping word if string satisfy some truly_rule regexp
  def self.is_truly? string
    found = VocabularyEntry.try_truly_rules(string) if string.split.count == 1
    return found
  end


  def self.words_matches_rules(string, options={})
    rule_features = []
    scope = VocabularyEntry
    scope.standard_rules.each do |rule|
      if string =~ Regexp.new(rule.regexp_rule)
        ret_val = rule.token
        ret_val ||= string.scan(Regexp.new(rule.regexp_rule)).first
        rule_features << ret_val
      end
    end
    return rule_features
  end


  def self.try_truly_rules(word)
    TextClass.all.each do |tc|
      truly_regexp = VocabularyEntry.make_regexp_for_truly_entries( tc.id )
      return truly_regexp[1] if word =~ Regexp.new(truly_regexp[0])
    end
    return nil
  end


  # Will return [regexp_rule_str, token] for catch all tokens which have 'truly' flag
  # options: :for_other_cities - true if need big rule for all other than passed text_class_id. At this case: [regexp_rule, nil]
  def self.make_regexp_for_truly_entries( text_class_id, options={} )
    big_regexp = ""
    return_token = nil
    options[:for_other_cities] ? scope = VocabularyEntry.truly.for_cities_other_than(text_class_id) : scope = VocabularyEntry.truly.for_city(text_class_id)
    scope.each do |word_or_rule|
      return_token = word_or_rule.token unless options[:for_other_cities]
      if word_or_rule.regexp_rule
        rule = word_or_rule.regexp_rule.delete("()")
      else
        rule = Regexp.escape word_or_rule.token
      end
      big_regexp << "#{rule}|"
    end
    big_regexp[-1] = "" unless big_regexp.empty?
    return [big_regexp, return_token]
  end


  protected


  def truly_rule_validation
    errors.add :token, "Should have value" if truly_city? && token.nil?
  end


  def token_uniqueness_for_tokens_only
    if token && !regexp_rule && VocabularyEntry.only_tokens.pluck(:token).include?(token)
      errors.add :token, "Should be unique"
    end
  end


end