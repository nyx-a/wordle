#! /usr/bin/env ruby

require 'webdrivers/chromedriver'

require_relative 'wordset.rb'
require_relative 'filter.rb'
require_relative 'tile.rb'

# https://www.nytimes.com/games/wordle/index.html
# https://www.wordle2.in


class Solver
  attr_reader :whole, :subset, :filter, :driver

  def initialize dictfile, url
    @tried  = Set.new ################ 安易な解決策
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
    @game_row = game_app.find_elements(:tag_name, 'game-row').map &:shadow_root
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

  def submit! word
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
  alias :<< :submit!

  def progress
    [@subset.size, @whole.size]
  end

  def win?
    matrix&.last&.all? :correct
  end

  def remaining
    @game_row.size - matrix.size
  end

  def foo
    if @subset.one?
      @subset.first
    else
      ow = @whole.order @subset
      os = @subset.order @subset
      ow.pop while @tried.include? ow.dig(-1,0)
      os.pop while @tried.include? os.dig(-1,0)
      [ow.last, os.last].max_by(&:last).first
    end
  end

  def auto!
    while !@subset.empty? and !win? and remaining.positive?
      word = foo
      puts "#{progress.inspect} #{word}"
      submit! word
      sleep 1
    end
    progress
  end

  def sample! n=1
    while n.positive? and remaining.positive?
      submit! @whole.sample
      n -= 1
      sleep 1 unless n.zero?
    end
    progress
  end
  alias :random! :sample!

  def check row
    f = Filter.new
    i = 0
    row.each do |t|
      case t.color
      when :correct then f.add_green  t.letter, i
      when :present then f.add_yellow t.letter, i
      when :absent  then f.add_black  t.letter, i
      else
        raise
      end
      i += 1
    end
    @subset.filter!{ f.pass? _1 }
    @filter.merge! f
    @tried.add row.to_s
    return self
  end

  def matrix
    @game_row.map do |r|
      arr = r.find_elements(:tag_name, 'game-tile').map do
        Tile.new(_1.attribute('letter'), _1.attribute('evaluation'))
      end
      Row.new(arr).nillize
    end.compact
  end
end


if ARGV.size == 2
  s = Solver.new ARGV.shift, ARGV.shift
  binding.irb
  # you can try `s.auto!`
  ObjectSpace.define_finalizer s do
    s.save
  end
else
  puts 'usage:'
  puts "  $ #{$0} Dictionary URL"
  puts
end

