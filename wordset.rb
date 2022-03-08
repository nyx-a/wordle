
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

  # { alphabet => Set(words) }
  def classify_by_letter
    alphabet = Hash.new{ _1[_2] = Set.new }
    for word in self
      for letter in word.chars.uniq
        alphabet[letter].add word
      end
    end
    return alphabet
  end

  # { word => linkage_score }
  def linkage
    common = classify_by_letter
    to_h do |word|
      [word, word.chars.uniq.map{ common[_1] }.inject(&:|).count]
    end
  end

  def order
    linkage.sort_by &:last
  end

  def top_score
    order.last
  end

  def im_feeling_lucky
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

