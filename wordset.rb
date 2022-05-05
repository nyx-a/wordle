
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
    drop(rand(0...size)).first
  end

  def anagram_list
    group_by{ _1.chars.sort }.select{ _2.size > 1 }.values
  end

  def angrm_list
    group_by{ _1.chars.uniq.sort }.select{ _2.size > 1 }.values
  end

  def anagram_of word
    letters = word.to_s.chars.sort
    select{ letters == _1.chars.sort } - [ word ]
  end

  def angrm_of word
    letters = Set.new word.to_s.chars
    select{ letters == Set.new(_1.chars) } - [ word ]
  end

  # letter subset
  def aaggmm_of word
    letters = Set.new word.to_s.chars
    select{ Set.new(_1.chars).subset? letters } - [ word ]
  end
end

