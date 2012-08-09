#!/usr/bin/env ruby

load 'tokens.rb'
load 'parser.rb'

class String
  def match_all regex
    self.to_enum(:scan, regex).map {Regexp.last_match}
  end

  def to_total_re
    /^#{self}$/
  end
end 

module Flat

  #language definition
  BASIC_TYPES = ['i','f','s','b','_']
  BASIC_TYPE_RE = "[#{BASIC_TYPES.join}]"

  MODIFIERS = ['+','*']
  MODIFIER_RE = "[#{MODIFIERS.join}]"

  BASIC_TOKEN_RE = "#{BASIC_TYPE_RE}(?:#{MODIFIER_RE}|[0-9]+)?"

  DATE_TYPES = ['a','A','b','B','c','d','H','I','j','m','M','p','S','U','w','W','x','X','Y','Z',' ']
  DATE_TYPES_RE = "[#{DATE_TYPES.join}]"
  DATE_TOKEN_RE = "%#{DATE_TYPES_RE}*%" 

  FIXED_FLOAT_TYPE = 'D'
  FIXED_FLOAT_SEP = 'e'
  FIXED_FLOAT_TOKEN_RE = "#{FIXED_FLOAT_TYPE}\\d+(?:#{FIXED_FLOAT_SEP}\\d+)?"

  TOKENS = [BASIC_TOKEN_RE, DATE_TOKEN_RE, FIXED_FLOAT_TOKEN_RE]
  TOKEN_RE =  "#{TOKENS.join('|')}"
  CAPTURE_TOKEN_RE =  /(#{TOKENS.join('|')})/

  LANGUAGE_RE = Regexp.new(/^(?:(#{TOKEN_RE}) *)+$/)

  #total regexes, i.e. regexes that must match the whole string
  TOTAL_BASIC_TYPE_RE = BASIC_TOKEN_RE.to_total_re
  TOTAL_FIXED_FLOAT_RE = FIXED_FLOAT_TOKEN_RE.to_total_re
  TOTAL_DATE_RE = DATE_TOKEN_RE.to_total_re

  #named regexes used for parsing tokens
  NAMED_BASIC_TYPE_RE = Regexp.new(/(?<type>#{BASIC_TYPE_RE})(?:(?<length>[0-9]+)|(?<modifier>#{MODIFIER_RE}))?/)
  NAMED_FIXED_FLOAT_RE = Regexp.new(/#{FIXED_FLOAT_TYPE}(?<length>\d+)(?:#{FIXED_FLOAT_SEP}(?<power>\d+))?/)
  NAMED_DATE_RE = Regexp.new(/%(?<format>#{DATE_TYPES_RE})%/)

  # Returns true if the supplied string is in
  # Flat's formatting language, as determined
  # by the LANGUAGE_RE regex.
  def self.string_in_lang(str)
    return (not (str =~ LANGUAGE_RE).nil?)
  end

  # Validates the supplied format string
  # and creates a parser from it
  def self.create_parser str
    return nil unless string_in_lang str
    lang = []
    str.match_all(CAPTURE_TOKEN_RE).each do |match|
      token_str = match[0]
      case token_str
      when TOTAL_BASIC_TYPE_RE
        token_pieces = token_str.match(NAMED_BASIC_TYPE_RE)
        t = Flat::Tokens.token_for_indicator(token_pieces[:type])
        t.position = match.begin(0)
        t.length = token_pieces[:length].nil? ? nil : token_pieces[:length].to_i
        t.modifier = token_pieces[:modifier]
        lang << t
      when TOTAL_FIXED_FLOAT_RE
        float_pieces = token_str.match(NAMED_FIXED_FLOAT_RE)
        t = Flat::Tokens::FixedFloatToken.new
        t.position = match.begin(0)
        t.power = float_pieces[:power].nil? ? nil : float_pieces[:power].to_i
        t.length = float_pieces[:length].to_i
        lang << t 
      when TOTAL_DATE_RE
        date_match = token_str.match(NAMED_DATE_RE)
        #TODO: Implement
      end
    end
    return FlatParser.new(lang)
  end
end


