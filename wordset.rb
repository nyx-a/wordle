
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
      fo.puts sort.join "\n"
    end
    return self
  end

  def letter_score
    full = self.size
    half = full / 2.0
    map{ _1.chars.uniq }.inject(&:+).tally.to_h do |letter,score|
      [letter, half<score ? full-score : score ]
    end
  end

  def word_score ls
    to_h do |word|
      [word, word.chars.uniq.map{ ls[_1] }.compact.sum ]
    end
  end

  def order_by_score target
    word_score(target.letter_score).sort_by(&:last).map &:first
  end

  def best_word target
    word_score(target.letter_score).max_by(&:last).first
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

