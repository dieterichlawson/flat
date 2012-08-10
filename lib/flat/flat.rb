class String
  def match_all regex
    self.to_enum(:scan, regex).map {Regexp.last_match}
  end
end 

module Flat
  # Validates the supplied format string
  # and creates a parser from it
  def self.create_parser str
    return nil unless Language.string_in_lang str
    lang = []
    str.match_all(Language::CAPTURE_TOKEN_RE).each do |match|
      token_str = match[0]
      case token_str
      when Language::TOTAL_SIMPLE_TYPE_RE
        token_pieces = token_str.match(Language::NAMED_SIMPLE_TYPE_RE)
        t = Flat::Tokens.token_for_indicator(token_pieces[:type])
        t.position = match.begin(0)
        t.length = token_pieces[:length].nil? ? nil : token_pieces[:length].to_i
        t.modifier = token_pieces[:modifier]
        lang << t
      when Language::TOTAL_FIXED_POINT_RE
        float_pieces = token_str.match(Language::NAMED_FIXED_POINT_RE)
        t = Flat::Tokens::FixedPointToken.new
        t.position = match.begin(0)
        t.power = float_pieces[:power].nil? ? nil : float_pieces[:power].to_i
        t.length = float_pieces[:length].to_i
        lang << t 
      when Language::TOTAL_DATE_RE
        date_match = token_str.match(Language::NAMED_DATE_RE)
        #TODO: Implement
      end
    end
    return Flat::Parser.new(lang)
  end
end
