# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :vocabulary_entry do
    token "MyString"
    regexp_rule "MyString"
    state 1
  end
end
