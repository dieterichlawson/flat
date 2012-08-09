module Flat
  module Language
    
    def self.to_total_re str
      /^#{str}$/
    end

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
    TOTAL_BASIC_TYPE_RE = to_total_re BASIC_TOKEN_RE
    TOTAL_FIXED_FLOAT_RE = to_total_re FIXED_FLOAT_TOKEN_RE
    TOTAL_DATE_RE = to_total_re DATE_TOKEN_RE

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
  end
end
