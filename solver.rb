
require_relative 'wordset.rb'
require_relative 'filter.rb'
require_relative 'tile.rb'

class Solver
  attr_reader   :whole, :subset, :tried, :filter
  attr_accessor :path, :changed

  def initialize path
    @path = path
    load_dictionary
    reset
  end

  def reset
    @subset = @whole.dup
    @tried  = [ ]
    @filter = Filter.new
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def load_dictionary
    if not File.readable? @path
      raise "cannot open file: #{@path.inspect}"
    end
    @changed = false
    @whole = Wordset.new @path
  end

  def save_dictionary
    if @changed
      @whole.savefile @path
      @changed = false
      @path
    end
  end

  def add_to_dictionary word
    @changed = !!@whole.add?(word) || @changed
  end

  def delete_from_dictionary word
    @subset.delete word
    @changed = !!@whole.delete?(word) || @changed
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def answer
    case @subset.size
    when 0
      nil # the answer is not in the dictionary @whole
    when 1
      @subset.first # perfect
    when 2
      @subset.sample # 1/2 chance to win
    else
      list = @whole.order_by_score @subset
      list.pop while @tried.include? list.last
      list.last
    end
  end

  def check tiles
    f = Filter.new
    tiles.each_with_index do |t,i|
      case t.color
      when :green  then f.add_green  t.letter, i
      when :yellow then f.add_yellow t.letter, i
      when :black  then f.add_black  t.letter
      else
        raise "#{t.color.inspect}"
      end
    end
    @subset.filter!{ f.pass? _1 }
    @filter.merge! f
    @tried.push tiles.map(&:letter).join
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def give_up?
    @subset.empty?
  end

  def progress
    [@subset.size, @whole.size]
  end

  def inspect
    "#{answer} (#{@subset.size}/#{@whole.size})"
  end
end

