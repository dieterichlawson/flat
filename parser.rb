module Flat
  class Parser
    attr_accessor :re
    attr_accessor :lang

    def initialize(lang)
      @lang = lang
      @re = re_from_language @lang
    end

    # returns true if the supplied string is in the parser's language
    def string_in_lang? str
      return (not (str =~ @re).nil?)
    end

    # Creates a regular expression from the 
    # supplied language
    def re_from_language lang
      regex = "^"
      lang.each do |token|
        regex += "(#{token.re})"
      end
      regex += "$"
      return Regexp.new(regex)
    end

    def parse str
      return nil unless string_in_lang? str
      result = []
      str.match(@re)[1..-1].each_with_index do |val,index|
        result << lang[index].translate(val)
      end
      return result - [:ignore]
    end
  end
end
