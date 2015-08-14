module Eclair
  class Matcher
    def initialize query
      @regex = Regexp.new(query.each_char.map{|c| "(#{c}".join(".*?"))
    end

    def match str
      str.match @regex
    end

    def find
    end

    def score a, b
    end

  end
end

