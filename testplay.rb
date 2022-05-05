#! /usr/bin/env ruby

require 'optparse'
require 'yaml'
require_relative 'solver.rb'

option = { }
o = OptionParser.new
o.on('-v',            '--verbose') { option[:v] = _1 }
o.on('-i file(dic)',  '--input')   { option[:i] = _1 }
o.on('-o file(yaml)', '--output')  { option[:o] = _1 }
o.on('-t word',       '--target')  { option[:t] = _1 }
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
def mark answer, try
  checked = answer.chars.map{ Tile.new _1, :black }
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
    a = solver.answer
    if a.nil?
      result = 0
      puts "give up".colorize :red
      break
    end
    tiles = mark target, a
    puts "#{i}: #{colorize tiles} #{solver.progress.join '/'}" if verbose
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
  game option[:t], solver, true
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

