module FlatTokens
  TOKENS = {}
  
  def self.token_for_indicator(indicator, position, length, modifier)
    return TOKENS[indicator].new(position,length,modifier) 
  end
  
  class BaseToken
    attr_accessor :position
    def initialize(position)
      @position = position
    end
  end

  class Token < BaseToken
    attr_accessor :length
    attr_accessor :modifier

    def initialize(position, length, modifier)
      super(position)
      @length = length
      @modifier = modifier
    end
  
    def get_default_re re
      if not @length.nil?
        return "#{re}{#{@length}}"
      elsif not @modifier.nil?
        return "#{re}#{@modifier}"
      else
        return re
      end
    end

    def translate str
      return str
    end
  end
  
  class IntToken < Token
    FlatTokens::TOKENS['i'] = self
    @indicator = 'i'

    def re
      regex = '(?:\+|-)?\\d'
      if not @length.nil?
        return "(?:(?:\\+|-)\\d{#{@length.to_i-1}}|\\d{#{@length.to_i}})"
      elsif not @modifier.nil?
        return "#{regex}#{@modifier}"
      else
        return regex
      end
    end

    def translate str
      return Integer(str)
    rescue ArgumentError => err
      return str.to_i
    end
  end

  class StringToken < Token
    FlatTokens::TOKENS['s'] = self
    @indicator = 's'
    
    def re
      get_default_re('.')
    end
  end

  class  FloatToken < Token
    FlatTokens::TOKENS['f'] = self
    @indicator = 'f'

    def get_re
       
    end
  end
 
  class BoolToken < Token
    FlatTokens::TOKENS['b'] = self
    @indicator = 'b'
    TRUE_TOKENS = ['t','tr','tru','true','y','ye','yes','1'] 
    FALSE_TOKENS = ['f','fa','fal','fals','false','n','no','0']
    
    def re
      return "(?:#{(TRUE_TOKENS + FALSE_TOKENS).join('|')})"
    end

    def translate str
      return TRUE_TOKENS.include?(str)
    end
  end

  class IgnoreToken < Token
    FlatTokens::TOKENS['_'] = self
    @indicator = '_'
    @re = '_'
  end

end
