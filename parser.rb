class FlatParser
  attr_accessor :re
  attr_accessor :lang
  
  def initialize(re,lang)
    @re = re
    @lang = lang
  end

  def string_in_lang? str
    return true
  end

  def parse str
    return nil unless string_in_lang? str
    result = []
    str.match(@re)[1..-1].each_with_index do |val,index|
      result << lang[index].translate(val)
    end
    return result
  end
end
