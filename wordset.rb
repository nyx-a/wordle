
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
    end.sort_by(&:last)
  end

  def top_score filter=nil
    order(filter).last
  end

  def im_feeling_lucky filter=nil
    top_score[0]
  end

  # As of Ruby 3.1.1, Set class doesn't have sample() method.
  def sample
    to_a.sample # crap
  end
end


if __FILE__ == $0
  w = Wordset.new ARGV.shift
  binding.irb
end

