
require 'set'


Pair = Struct.new :letter, :position do
  def positive? word
    word[@position] == @letter
  end

  def negative? word
    not positive? word
  end

  def near_miss? word
    negative? and word.include? @letter
  end

  def to_s
    "#{letter}:#{position}"
  end
  alias :inspect :to_s
end


class Filter
  attr_reader :green, :yellow, :black

  def initialize
    @green  = Set.new
    @yellow = Set.new
    @black  = Set.new
  end

  def green! letter, pos
    @green.add Pair.new letter, pos
    return self
  end

  def yellow! letter, pos
    @yellow.add Pair.new letter, pos
    return self
  end

  def black! *letters
    @black.replace @black + letters.join.chars
    return self
  end

  def pass? word
    return false if word =~ /[#{@black.join}]/
    for g in @green
      return false if g.negative? word
    end
    for y in @yellow
      return false unless y.near_miss? word
    end
    return true
  end

  def novelty word, freq
    letters = @black.union @green.map(&:letter)#, @yellow.map(&:letter)
    idx = 0
    word.chars.map do |letter|
      cursor = Pair.new letter, idx
      idx += 1
      case
      when letters.include?(letter) then 0
      #when  @black.include?(letter) then 0
      #when  @green.include?(cursor) then 0
      when @yellow.include?(cursor) then 0
      else
        freq[letter]
      end
    end
  end

  def inspect
    instance_variables.map do
      "#{_1[1]}{#{instance_variable_get(_1).map(&:to_s).join(' ')}}"
    end.join ' '
  end
end


if __FILE__ == $0
  f = Filter.new
  binding.irb
end

