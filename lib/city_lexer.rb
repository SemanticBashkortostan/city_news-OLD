#coding: utf-8
require 'set'

class CityLexer


  def initialize options={}
    @quote_syms = ['"', '«', '»']
    @space_sym = ' '
    @dash_sym = '-'
    @comma_sym = ','
    @colon_sym = ':'
    @divide_syms = [":", "-", ";", ","]
    @big_letters = /\b[А-ЯA-Z]/
    @letters = /[[:word:]]/

    @stop_words = %w( большой   бы
                      быть  в   весь
                      вот   все   всей
                      вы  говорить  год
                      да  для   до
                      еще   же  знать
                      и   из  к
                      как   который 
                      мы  на  наш
                      не  него  нее
                      нет   них   но
                      о   один  она
                      они   оно   оный
                      от  ото   по
                      с   свой  себя
                      сказать   та  такой
                      только  тот   ты
                      у   что   это
                      этот  я )
    @stop_words = @stop_words.to_set

    @city_news_mode = 0
    @city_info = {:text_class_id => options[:text_class_id], :regexp => options[:main_city_regexp], :other_classes => options[:other_classes]}        
  end


  def city_news_mode=(val)
    @city_news_mode = val    
  end


  def get_tokens_hash text, options={}
    text = text.clone.squeeze(" ")
    text[text.length] = "." if text[text.length-1] =~ /[[:word:]]/

    token = ""
    tokens_hash = {}
    quote_end = true
    comma = false
    is_direct_speech = false
    is_direct_speech_cntr = 0

    token_num = 0
    i = -1
    while i < text.length - 1
      i += 1
      if token.empty?        
        if @quote_syms.include?( text[i] )
          # Priority!
          #REFACTOR!
          if is_direct_speech
            is_direct_speech_cntr += 1
            if is_direct_speech_cntr == 2
              is_direct_speech = false
              is_direct_speech_cntr = 0
            end
          elsif not is_colon_direct_speech?(i, text)
            quote_end = false
            token << text[i]
          else 
            is_direct_speech = true
            is_direct_speech_cntr = 1
          end
        elsif (text[i] =~ @big_letters) || !quote_end
          token << text[i]
        end
      else
        if quote_end # If not quoted token
          if text[i] == @space_sym && not( text[i+1] =~ @big_letters )
            tokens_hash[token], token_num = get_token_with_token_num(token, token_num, comma, text, options)
            token = ""
            comma = false
          elsif text[i] == @comma_sym
            if text[i+1, i+2] =~ @big_letters
              token << text[i]
              comma = true
            else
              tokens_hash[token], token_num = get_token_with_token_num(token, token_num, comma, text, options)
              token = ""
              comma = false
            end
          elsif text[i] == @dash_sym && ( text[i+1] =~ @big_letters )
            token << text[i]
          elsif text[i+1] == nil
            tokens_hash[token], token_num = get_token_with_token_num(token, token_num, comma, text, options)         
            token = ""
            comma = false
          else
            token << text[i]
          end
          # If quoted token
        else
          if @quote_syms.include?(text[i])
            if direct_speech?(text[i+1..i+3])
              i = i - token.length - 1 
              quote_end = true
              token = ""
              is_direct_speech = true
              is_direct_speech_cntr = 0
            elsif !quote_end
              token << text[i]
              quote_end = true     
              tmp_opts = options.merge(:quoted => true)           
              tokens_hash[token], token_num = get_token_with_token_num(token, token_num, comma, text, tmp_opts)                  
              token = ""
            end
          else
            token << text[i]
          end
        end
      end
    end
    return tokens_hash
  end


  def get_token_with_token_num(token, token_num, comma, text, options={})
    is_first_token = (token_num == 0)

    left_context = text.scan(left_regexp(token)).flatten.first
    right_context = text.scan(right_regexp(token)).flatten.last
    token_num += 1 if right_context

    # If first word in token is stop word then delete it
    if is_first_token
      splitted_tokens = token.split(" ")
      if @stop_words.include?( splitted_tokens.first.mb_chars.downcase.to_s )
        token[0...splitted_tokens.first.length] = "" 
      else 
        options.merge!( {:is_first_token => true} )
      end
      return [{}, token_num+1] if token.empty?
    end

    hash = { :comma => comma, :token_pos => token_num, :left_context => left_context, :right_context => right_context }

    hash.merge!(options) unless options.empty?  

    if @city_news_mode == 1
      if !@city_info.empty? && token =~ @city_info[:regexp]
        hash.merge!( {:text_class_id => @city_info[:text_class_id], :is_main_class => true} ) 
      else
        @city_info[:other_classes].each { |text_class_id, regexp|
          if token =~ regexp
            hash.merge!( {:text_class_id => text_class_id, :is_main_class => false } )
            break
          end
        }
      end
    end
    return [hash, token_num+1]
  end


  def direct_speech? str3
    if str3[0] == @space_sym
      if str3[1] == @dash_sym
        true
      elsif str3[1] == @comma_sym && str3[2] == @dash_sym
        true
      end
    elsif str3[0] == @dash_sym || (str3[0] == @comma_sym && str3[1] == @dash_sym)
      true
    end
  end


  def is_colon_direct_speech? i, text
    (i == 1 && text[i-1].include?(@colon_sym)) || (i > 1 && text[i-2..i-1].include?( @colon_sym ))  
  end


  def left_regexp word
    Regexp.new "([[:word:]]+.)(#{word})"
  end


  def right_regexp word 
    Regexp.new "(#{word})+.([[:word:]]+)"
  end

end