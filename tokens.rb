module FlatTokens
  TOKENS = {}
  
  def self.token_for_indicator(indicator)
    return TOKENS[indicator].new
  end
  
  class BaseToken
    attr_accessor :position
  end

  class DecimalToken < BaseToken
    attr_accessor :power
    attr_accessor :length

    def re
      "(?:(?:\\+|-)\\d{#{@length-1}}|\\d{#{@length}})"
    end

    def translate str
      base = str.to_f
      return base / (10**@power)
    end
  end

  class Token < BaseToken
    attr_accessor :length
    attr_accessor :modifier

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
        return "(?:(?:\\+|-)\\d{#{@length-1}}|\\d{#{@length}})"
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
    #TODO: Implement floats
    FlatTokens::TOKENS['f'] = self
    @indicator = 'f'

    def get_re
       
    end
  end
 
  class BoolToken < Token
    #TODO: Add back multi-char options and think through allowing padding
    #TODO: Allow users to override true and false
    FlatTokens::TOKENS['b'] = self
    @indicator = 'b'
    TRUE_TOKENS = ['t','y','1'] 
    FALSE_TOKENS = ['f','n','0']
    
    def re
      return "(?:#{(TRUE_TOKENS + FALSE_TOKENS + TRUE_TOKENS.map{|x| x.upcase} + FALSE_TOKENS.map{|x| x.upcase}).join('|')})"
    end

    def translate str
      return TRUE_TOKENS.include?(str.downcase)
    end
  end

  class IgnoreToken < Token
    #TODO: implement
    #TODO: Think through how to remove ignored stuff form final output
    #IDEA: use :ignore symbol that is stripped out at end
    FlatTokens::TOKENS['_'] = self
    @indicator = '_'
    @re = '_'
  end

end
