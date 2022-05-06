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

def sort_vk hash
  hash.sort_by{ |k,v| [v,k] }.to_h # ソート済みハッシュという矛盾
end

def text_bar_chart array, width=50
  aoa = array.tally.sort_by &:first         # array of array
  mll = aoa.map{ _1[0].inspect.length }.max # max label length
  ma  = Float aoa.map{ _1[1] }.max          # max amount
  aoa.map do |label,amount|
    bar_length = (amount / ma * width).round
    "%#{mll}s | #{'*' * bar_length} (%d)" % [label.inspect, amount]
  end.join "\n"
end

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
    angrm  -= anagram
    puts "anagram .. #{anagram.inspect}"
    puts "angrm+ ... #{  angrm.inspect}"
    puts
    array.concat anagram
    array.concat angrm
  end
  array.unshift option[:t]
  for w in array
    game w, solver, true
  end
else
  if option[:o].nil?
    option[:o] = "result.#{option[:i]}.yaml"
  end
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
  YAML.dump sort_vk(result), handle

  # chart
  txt = text_bar_chart result.values
  if option[:v]
    puts txt
  end
  handle.puts
  handle.puts txt.gsub(/^/, '# ')
  handle.close
end

