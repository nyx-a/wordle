
require 'set'


# Count and Position
class Cntpos
  attr_reader :count, :capped, :bingo, :boo

  def initialize *args
    @count  = args.shift || 0
    @capped = args.shift || false
    @bingo  = args.shift || Set.new
    @boo    = args.shift || Set.new
  end

  def merge other
    Cntpos.new(
      [@count, other.count].max,
      @capped || other.capped,
      @bingo + other.bingo,
      @boo + other.boo,
    )
  end

  def merge! other
    @count  = [@count, other.count].max
    @capped = @capped || other.capped
    @bingo.replace @bingo & other.bingo
    @boo.replace @boo & other.boo
  end

  def clone
    Cntpos.new @count, @capped, @bingo.clone, @boo.clone
  end

  def count_up
    @count = @count + 1
  end

  def count_stop
    @capped = true
  end

  def here_it_is position
    @bingo.add position
  end

  def not_here position
    @boo.add position
  end

  def number_okay? word, letter
    word.count(letter).send(@capped ? :== : :>=, @count)
  end

  def position_okay? word, letter
    if @bingo
      if not @bingo.all?{ word[_1] == letter }
        return false
      end
    end
    if @boo
      if not @boo.all?{ word[_1] != letter }
        return false
      end
    end
    return true
  end

  def inspect
    [
      @capped ? 'Exactly' : 'At least',
      @count,
      'o=' + @bingo.join(','),
      'x=' + @boo.join(','),
    ].join(' ')
  end
end


class Filter
  attr_reader :key

  def initialize
    @key = Hash.new{ |h,k| h[k] = Cntpos.new } # { letter => Cntpos }
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

  def add_black letter, position
    @key[letter].count_stop
    @key[letter].not_here position
    return self
  end

  def pass? word
    @key.all? do |l,cp|
      cp.number_okay?(word, l) and cp.position_okay?(word, l)
    end
  end

  def inspect
    instance_variables.map do
      "#{_1[1]}{#{instance_variable_get(_1).map(&:to_s).join(' ')}}"
    end.join ' '
  end
end


if __FILE__ == $0
  f = Filter.new
  binding.irb
end

