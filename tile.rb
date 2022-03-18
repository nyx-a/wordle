
require 'colorize'

class Tile
  attr_reader :letter, :color

  def letter= o
    @letter = o
  end

  def color= o
    case o&.to_sym
    when :absent, :black  then @color = :black
    when :present,:yellow then @color = :yellow
    when :correct,:green  then @color = :green
    when nil              then @color = nil
    else
      raise "invalid color #{o}"
    end
  end

  def initialize letter, color
    self.letter = letter
    self.color  = color
  end

  def empty?
    @letter.nil? and @color.nil?
  end

  def invalid?
    @letter.nil? or @color.nil?
  end

  def to_s
    empty? ? '-' : @letter.colorize(@color)
  end

  def black?
    @color == :black
  end

  def yellow?
    @color == :yellow
  end

  def green?
    @color == :green
  end

  def inspect
    empty? ? '-' : "#{@letter.upcase} #{@color}"
  end
end

