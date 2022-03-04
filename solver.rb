#! /usr/bin/env ruby

require 'webdrivers/chromedriver'

require_relative 'wordset.rb'
require_relative 'filter.rb'
require_relative 'tile.rb'

# https://www.nytimes.com/games/wordle/index.html
# https://www.wordle2.in


class Solver
  attr_reader(*%i`whole subset filter driver`)

  def initialize dictfile, url
    @dfile  = dictfile
    @whole  = Wordset.new @dfile
    @subset = @whole.clone
    @filter = Filter.new

    @driver = Selenium::WebDriver.for :chrome
    @driver.manage.timeouts.implicit_wait = 10
    @driver.navigate.to url

    # click first x
    game_app = @driver.find_element(:tag_name, 'game-app').shadow_root
    game_modal = game_app.find_element(:tag_name, 'game-modal').shadow_root
    game_modal.find_element(:css, 'div.close-icon').click

    # get rows
    @row = game_app.find_elements(:tag_name, 'game-row').map &:shadow_root
  end

  def enter word
    @driver.action.send_keys(word, :enter).perform
  end

  def erase
    word = matrix.last.to_s
    @driver.action.send_keys([:backspace] * word.length).perform
    @whole.delete word
    @subset.delete word
    @dflag = true
    word
  end

  def save
    if @dflag
      @whole.savefile @dfile
      puts %`Saved: "#{@dfile}"`
      @dflag = false
      true
    end
  end

  def submit word
    before = matrix.size
    enter word
    after = matrix.size

    if matrix.last.invalid? or before == after
      # It could be "Not enough letters"
      p "Not in word list => #{word}"
      erase
    else
      check matrix.last
    end
    return progress
  end

  def progress
    [@subset.size, @whole.size]
  end

  def w
    @whole.im_feeling_lucky @filter
  end

  def s
    @subset.im_feeling_lucky @filter
  end

  def check row
    f = Filter.new
    idx = 0
    row.each do |t|
      case t.color
      when :present then f.add_yellow t.letter, idx
      when :correct then f.add_green t.letter, idx
      when :absent  then f.add_black t.letter
      else
        raise
      end
      idx += 1
    end
    @subset.filter!{ f.pass? _1 }
    @filter.merge f
    return self
  end

  def matrix
    @row.map do |r|
      arr = r.find_elements(:tag_name, 'game-tile').map do
        Tile.new(_1.attribute('letter'), _1.attribute('evaluation'))
      end
      Row.new(arr).nillize
    end.compact
  end
end


if ARGV.size == 2
  sol = Solver.new ARGV.shift, ARGV.shift
  binding.irb
else
  puts 'usage:'
  puts "  $ #{$0} Dictionary URL"
  puts
end
