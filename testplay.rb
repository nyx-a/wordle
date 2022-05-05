#! /usr/bin/env ruby

require 'optparse'
require 'yaml'
require_relative 'solver.rb'

option = { }
o = OptionParser.new
o.on('-v',      '--verbose', 'work with no --target') { option[:v] = _1 }
o.on('-i file', '--input',   'word list to use')      { option[:i] = _1 }
o.on('-o file', '--output',  'written in YAML')       { option[:o] = _1 }
o.on('-t word', '--target',  'single word to test')   { option[:t] = _1 }
o.on('-a',      '--anagram', 'work with --target')    { option[:a] = _1 }
o.parse! ARGV

if option[:i].nil?
  puts o.help
  exit
end

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def colorize array_of_tiles
  array_of_tiles.map(&:to_s).join
end

# 採点
def mark target, try
  if target.size != try.size
    raise "word length mismatched: #{target} #{try}"
  end
  checked = target.chars.map{ Tile.new _1, :black }
  result  =    try.chars.map{ Tile.new _1, :black }
  # Green
  result.each_index do |i|
    if result[i].letter == checked[i].letter
      result [i].color = :green
      checked[i].color = :green # not :black
    end
  end
  # Yellow
  result.each_index do |i|
    if result[i].black?
      j = checked.index do |c|
        c.black? and c.letter == result[i].letter
      end
      if j
        result [i].color = :yellow
        checked[j].color = :yellow # not :black
      end
    end
  end
  return result
end

def game target, solver, verbose
  result = nil
  puts "   #{target}" if verbose
  for i in 1..99
    try = solver.answer
    if try.nil?
      result = 0
      puts "give up".colorize :red
      break
    end
    tiles = mark target, try
    puts '%2d %s %5d/%5d' % [i, colorize(tiles), *solver.progress] if verbose
    if tiles.all? &:green?
      result = i
      break
    end
    solver.check tiles
  end
  solver.reset
  puts if verbose
  return result
end

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

solver = Solver.new option[:i]
result = { }

if option[:t]
  array = [ ]
  if option[:a]
    anagram = solver.whole.anagram_of option[:t]
    angrm   = solver.whole.  angrm_of option[:t]
    #aaggmm  = solver.whole. aaggmm_of option[:t]
    puts "anagram .. #{anagram.inspect}"
    puts "angrm .... #{  angrm.inspect}"
    #puts "aaggmm ... #{ aaggmm.inspect}"
    puts
    array.concat anagram
    array.concat angrm
    #array.concat aaggmm
  end
  array.unshift option[:t]
  for w in array.uniq
    game w, solver, true
  end
else
  if File.exist? option[:o]
    puts "file already exist: #{option[:o].inspect}"
    puts
    exit
  else
    handle = File.open option[:o], 'w'
  end

  for word in solver.whole
    result[word] = game word, solver, option[:v]
  end
  YAML.dump result, handle
end

