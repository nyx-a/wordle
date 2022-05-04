
require 'colorize'

def BK s
  s.to_s.chars.map{ Tile.new _1, :black }
end

def YL s
  s.to_s.chars.map{ Tile.new _1, :yellow }
end

def GR s
  s.to_s.chars.map{ Tile.new _1, :green }
end

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

class Tile
  COLOR = {
    black:  { color: :white, background: :light_black },
    yellow: { color: :black, background: :yellow      },
    green:  { color: :black, background: :green       },
  }.freeze

  attr_reader :letter, :color

  def letter= o
    if o.nil?
      @letter = nil
    else
      if o.size != 1
        raise "give just one letter: #{o.inspect}"
      end
      @letter = o.to_s.downcase
    end
  end

  def color= o
    if o.nil?
      @color = nil
    else
      case o.to_s.downcase.to_sym
      when :absent, :black  then @color = :black
      when :present,:yellow then @color = :yellow
      when :correct,:green  then @color = :green
      else
        raise "invalid color: #{o.inspect}"
      end
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
    @letter.nil? ? '-' : @letter.colorize(COLOR[@color])
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
    empty? ? '-' : "#{@letter}(#{@color})"
  end
end

