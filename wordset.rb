
require 'set'


class Wordset < Set
  def initialize something=nil
    if something.respond_to? :each
      super something
    else
      super()
      loadfile something.to_s
    end
  end

  def loadfile path
    open(path) do |fi|
      replace fi.read.downcase.split
    end
    return self
  end

  def savefile path
    open(path, 'w') do |fo|
      fo.puts join "\n"
    end
    return self
  end

  def letter_frequency
    join.chars.tally
  end

  def order filter=nil
    frequency = letter_frequency
    to_h do |word|
      score = if filter
                filter.novelty word, frequency
              else
                word.chars.map{ frequency.fetch _1, 0 }
              end
      [word, score]
    end.sort_by{ _1.last.sum }
  end

  def im_feeling_lucky filter=nil
    order(filter).last[0]
  end
end


if __FILE__ == $0
  w = Wordset.new ARGV.shift
  binding.irb
end

