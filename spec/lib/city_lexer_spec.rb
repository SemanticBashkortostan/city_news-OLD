#coding:utf-8

require 'spec_helper'

describe "CityLexer" do 
  it "should correctly return result for specific string" do
    str1 = 'Hello  "    dear country  " in the Russia, America   and I live with cats, dogs and parrots. '
    str1_test = {
                  "Hello"=>{:comma=>false, :token_pos=>0, :left_context=>nil, :right_context=>nil, :token=>"Hello", :is_first_token=>true}, 
                  "dear country"=>{:quoted=>true, :token_pos=>2, :left_context=>"Hello ", :right_context=>"in", :comma => false, 
                                         :token => "dear country"}, 
                  "Russia, America"=>{:comma=>true, :token_pos=>4, :left_context=>"the ", :right_context=>"and", 
                                      :token => "Russia, America"}, 
                  "I"=>{:comma=>false, :token_pos=>6, :left_context=>"and ", :right_context=>"live", :token => "I"}  
                }
     city_lexer = CityLexer.new    
     city_lexer.get_tokens_hash(str1).should == str1_test
     city_lexer.get_tokens_hash(str1).should == str1_test
  end

  it "should correctly return result for direct speech string" do    

    str3 = 'Иван сказал: "Вчера я был в Гостях"'
    str3_test = { "Иван"=>{:comma=>false, :token_pos=>1, :left_context=>nil, :right_context=>"сказал", :token=>"Иван", :is_first_token=>true}, 
                  "Вчера"=>{:comma=>false, :token_pos=>3, :left_context=>nil, :right_context=>"я", :token=>"Вчера" }, 
                  "Гостях"=>{:comma=>false, :token_pos=>4, :left_context=>"в ", :right_context=>nil, :token=>"Гостях" } }
    str4 = '"Не верю Я тебе" - ответила Жена.'
    str4_test = { "Я"=>{:comma=>false, :token_pos=>3, :left_context=>"верю ", :right_context=>"тебе", :token=>"Я"}, 
                  "Жена"=>{:comma=>false, :token_pos=>4, :left_context=>"ответила ", :right_context=>nil, :token=>"Жена"} }
    str5 = '"Салават Юлавев" тем временем проиграл казанскому Ак-Барсу со счетом 4-3, теперь сыграть осталось только Ска, Локомотиву и ЦСКА.'  
    str5_test = {"Салават Юлавев"=>{:comma=>false, :token_pos=>1, :left_context=>nil, :right_context=>"тем", :token=>"Салават Юлавев", :quoted=>true, :is_first_token=>true}, 
                  "Ак-Барсу"=>{:comma=>false, :token_pos=>3, :left_context=>"казанскому ", :right_context=>"со", :token=>"Ак-Барсу"}, 
                  "Ска, Локомотиву"=>{:comma=>true, :token_pos=>5, :left_context=>"только ", :right_context=>"и", :token=>"Ска, Локомотиву"}, 
                  "ЦСКА"=>{:comma=>false, :token_pos=>6, :left_context=>"и ", :right_context=>nil, :token=>"ЦСКА"} }

    city_lexer = CityLexer.new        
    city_lexer.get_tokens_hash(str3).should == str3_test
    city_lexer.get_tokens_hash(str4).should == str4_test
    city_lexer.get_tokens_hash(str5).should == str5_test
  end
end






# def testing
#   left_regexp = /([[:word:]]+.)(\"Салават Юлавев\")/
#   str1 = 'Hello  "    dear country  " in the Russia, America   and I live with cats, dogs and parrots. '
#   str1_shld = 'Hello "dear country" in the Russia,America and i live with cats, dogs, parrots.'
#   str1_feature_vector = {
#     'dear_country' => {:pos => 1, :left_context => nil, :right_context => 'in', :sentence_pos => 0, :quoted => true},
#     'Russia' => {:pos => 4, :left_context => 'the', :right_context => nil, :sentence_pos => 0 },
#     'America' => {:pos => 5, :left_context => 'the', :right_context => nil, :sentence_pos => 0 }
#   }
#   str2 = ' What is      Your Name "Sayonara  " baby   .'
#   str2_shld = 'What is Your Name bla "Sayonara" baby.'
#   str2_feature_vector = {
#     'What' => {:pos => 0, :left_context => nil, :right_context => 'is', :sentence_pos => 0},
#     'Your Name' => {:pos => 2, :left_context => nil, :right_context => 'bla', :sentence_pos => 0},
#     'Sayonara' => {:pos => 4, :left_context => 'bla', :right_context => 'baby', :sentence_pos => 0, :quoted => true}
#   }

#   str3 = 'Иван сказал: "Вчера я был в Гостях"'
#   str4 = '"Не верю Я тебе" - ответила Жена.'
#   str5 = 'Иван говорит: "Я был в гостях!". На это поступил ответ: "Не верю Я тебе",- ответила Жена. "Салават Юлавев" тем временем проиграл казанскому Ак-Барсу со счетом 4-3, теперь сыграть осталось только Ска, Локомотиву и ЦСКА.'  

#   p get_tokens_hash(str1)
#   str1_test = {"Hello"=>{:comma=>false, :token_pos => 0}, "\" dear country \""=>{:quoted=>true, :token_pos => 1}, "Russia, America"=>{:comma=>true, :token_pos => 2}, "I"=>{:comma=>false, :token_pos => 3}}
#   p get_tokens_hash(str1) == str1_test
#   # p get_tokens_hash(str3)
#   p str4
#   p get_tokens_hash(str4)
#   p str5
#   p get_tokens_hash(str5)
#   p "Вчера я был у Маши, она готовила борщ."
#   p get_tokens_hash "Вчера я был у Маши, она готовила борщ"

#   tst1 = "Уфимец Семен Елистратов ограничился личным «золотом» чемпионата России"
#   tst2 =  "В подмосковной Коломне прошел первый день чемпионата России по шорт-треку на отдельных дистанциях"
#   tst3 = "На дистанции 1500 метров победил уфимец Семен Елистратов. Вторым стал еще один представитель Уфы -..."

#   p get_tokens_hash tst1
#   p get_tokens_hash tst2
#   p get_tokens_hash tst3
#   # p get_tokens_hash(str2) == str2_shld
# end


# Filtering:
## Clear all > 1 spaces
## Clear all spaces near [ , - " << ]
#=> "Hello  "    dear country  " in the Russia, America. => "Hello "dear country" in the Russia,America"
#=> "Hello  "    dear, country  " in the Russia, America. => "Hello "dear, country" in the Russia,America" =>
##... ["Hello" => {:token_pos => 0, :left_cntxt => nil, :right_cntxt => QUOTED, :sentence_pos => 0 } , ...'"dear_country"', "in", "the", "Russia", "America"]
##... " "dear, country" in the Russia,America" =>
##... "dear_country" => "in the Russia,America" => "Russia", "America", :left_context => 'the', :right_context => nil
