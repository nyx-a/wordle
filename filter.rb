
require 'set'


# Count and Position
class Cntpos
  attr_reader :count, :capped, :positive, :negative

  def initialize *args
    @count    = args.shift || 0
    @capped   = args.shift || false
    @positive = args.shift || Set.new
    @negative = args.shift || Set.new
  end

  def merge other
    Cntpos.new(
      [@count, other.count].max,
      @capped || other.capped,
      @positive + other.positive,
      @negative + other.negative,
    )
  end

  def clone
    Cntpos.new @count, @capped, @positive.clone, @negative.clone
  end

  def count_up
    @count = @count + 1
  end

  def count_stop
    @capped = true
  end

  def here_it_is position
    @positive.add position
  end

  def not_here position
    @negative.add position
  end

  def number_okay? word, letter
    word.count(letter).send(@capped ? :== : :>=, @count)
  end

  def position_okay? word, letter
    if @positive
      if not @positive.all?{ word[_1] == letter }
        return false
      end
    end
    if @negative
      if not @negative.all?{ word[_1] != letter }
        return false
      end
    end
    return true
  end

  def inspect
    [
      @capped ? 'Exactly' : 'At least',
      @count,
      ',',
      'Certainly=' + @positive.sort.inspect,
      'Never=' + @negative.sort.inspect,
    ].join(' ')
  end
end


class Filter
  attr_reader :key

  def initialize
    # { letter => Cntpos }
    @key = Hash.new{ |h,k| h[k] = Cntpos.new }
  end

  def [] letter
    @key.fetch letter
  end

  def merge! other
    @key.merge! other.key do |l,a,b|
      a.merge b
    end
  end

  def add_green letter, position
    @key[letter].count_up
    @key[letter].here_it_is position
    return self
  end

  def add_yellow letter, position
    @key[letter].count_up
    @key[letter].not_here position
    return self
  end

  def add_black letter
    @key[letter].count_stop
    return self
  end

  def pass? word
    @key.all? do |l,cp|
      cp.number_okay?(word, l) and cp.position_okay?(word, l)
    end
  end

  def unknown
    ('a'..'z').to_a - @key.keys
  end

  def inspect
    s = @key.map { |l,cp| "#{l} #{cp.inspect}" }.join "\n"
    ['{', s, '}'].join "\n"
  end
end


if __FILE__ == $0
  f = Filter.new
  binding.irb
end

