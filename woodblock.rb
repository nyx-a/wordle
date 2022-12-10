
# 人間用

def stretch alphabet
  ('a'..'z').to_a.map { alphabet.include?(_1) ? _1 : ' ' }
end

class Woodblock
  def initialize n
    @block = Array.new(n){ ('a'..'z').to_a }
  end

  def apply object
    for l,c in object.solver.filter.key
      if c.count.zero?
        @block.each{ _1.delete l }
      else
        c.positive.each{ |i| @block[i].reject!{ |x| x != l  } }
        c.negative.each{ |i| @block[i].reject!{ |x| x == l  } }
      end
    end
  end

  def inspect
    v = @block.map{ stretch _1 }.transpose
    v.reject!{ _1.all? ' ' }
    v.map{ _1.join.upcase }.join("\n")
  end
end

