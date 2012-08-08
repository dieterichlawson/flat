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

# langauge definition

TYPES = ['i','f','s','b','_']
TYPE_RE = "[#{TYPES.join}]"

MODIFIERS = ['+','*']
MODIFIER_RE = "[#{MODIFIERS.join}]"

#TODO: Figure out better name than token
TOKEN_RE = "#{TYPE_RE}(?:#{MODIFIER_RE}|[0-9]+)?"

DATE_TYPES = ['a','A','b','B','c','d','H','I','j','m','M','p','S','U','w','W','x','X','Y','Z']
DATE_TYPES_RE = "[#{DATE_TYPES.join} ]"
DATE_RE = "%#{DATE_TYPES.join}* %" 

FLOAT_TYPE = 'D'
FLOAT_SEP = 'e'
FLOAT_RE = "#{FLOAT_TYPE}\\d+(?:#{FLOAT_SEP}\\d+)?"

STATEMENTS = [TOKEN_RE, DATE_RE, FLOAT_RE]

STATEMENT_RE =  "#{STATEMENTS.join('|')}"
CAPTURE_STATEMENT_RE =  /(#{STATEMENTS.join('|')})/

LANGUAGE_RE = Regexp.new(/^(?:(#{STATEMENT_RE}) *)+$/)

#total regexes, i.e. regexes that must match the whole string
TOTAL_TOKEN_RE = TOKEN_RE.to_total_re
TOTAL_FLOAT_RE = FLOAT_RE.to_total_re
TOTAL_DATE_RE = DATE_RE.to_total_re

#named regexes used for parsing
NAMED_TOKEN_RE = Regexp.new(/(?<type>#{TYPE_RE})(?:(?<length>[0-9]+)|(?<modifier>#{MODIFIER_RE}))?/)
NAMED_FLOAT_RE = Regexp.new(/#{FLOAT_TYPE}(?<length>\d+)(?:#{FLOAT_SEP}(?<power>\d+))?/)
NAMED_DATE_RE = Regexp.new(/%(?<format>#{DATE_TYPES_RE})%/)

#def string_in_lang str
#  return not (str =~ LANGUAGE_RE).nil?
#end

def create_parser str
#  return nil unless string_in_lang str
  lang = []
  str.match_all(CAPTURE_STATEMENT_RE).each do |match|
    token = match[0]
    vals = {:position => match.begin(0)}
    case token
    when TOTAL_TOKEN_RE
      token_match = token.match(NAMED_TOKEN_RE)
      t = FlatTokens.token_for_indicator(token_match[:type])
      t.position = match.begin(0)
      t.length = token_match[:length].nil? ? nil : token_match[:length].to_i
      t.modifier = token_match[:modifier]
      lang << t
    when TOTAL_FLOAT_RE
      float_match = token.match(NAMED_FLOAT_RE)
      t = FlatTokens::DecimalToken.new
      t.position = match.begin(0)
      t.power = float_match[:power].nil? ? nil : float_match[:power].to_i
      t.length = float_match[:length].to_i
      lang << t 
    when TOTAL_DATE_RE
      date_match = token.match(NAMED_DATE_RE)

    end
  end
  return FlatParser.new(re_from_language(lang),lang)
end

def re_from_language lang
  regex = "^"
  lang.each do |token|
    regex += "(#{token.re})"
  end
  return Regexp.new(regex)
end
