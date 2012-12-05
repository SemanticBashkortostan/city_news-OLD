# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :feed do
    title "MyString"
    url "MyString"
    summary "MyText"
    published_at "2012-12-05 22:17:39"
    text_class_id 1
  end
end
