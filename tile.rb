
require 'colorize'

class Tile
  COLOR = {
    absent:  { color: :white, background: :black  },
    present: { color: :black, background: :yellow },
    correct: { color: :black, background: :green  },
  }

  attr_reader :letter, :color

  def initialize letter, color
    @letter = letter
    @color  = color&.to_sym
  end

  def empty?
    @letter.nil? and @color.nil?
  end

  def invalid?
    @letter.nil? or @color.nil?
  end

  def to_s
    empty? ? '-' : @letter.upcase.colorize(**COLOR[@color])
  end

  def inspect
    empty? ? '-' : "#{@letter.upcase} #{@color}"
  end
end

class Row
  attr_reader :tiles

  def initialize tiles
    @tiles = tiles
  end

  def empty?
    @tiles.all? &:empty?
  end

  def invalid?
    @tiles.all? &:invalid?
  end

  def count
    @tiles.count{ not _1.empty? }
  end

  def nillize
    empty? ? nil : self
  end

  def to_s
    @tiles.map(&:letter).join
  end

  def each(...)
    @tiles.each(...)
  end
end

