#! /usr/bin/env ruby

require_relative 'solver.rb'
require 'webdrivers/chromedriver'

class Wordle
  attr_reader :driver, :url, :solver

  def initialize path, url='https://www.nytimes.com/games/wordle/index.html'
    @url    = url
    @solver = Solver.new path
    open
    ObjectSpace.define_finalizer @solver do
      if path = @solver.save_dictionary
        puts "dictionary saved: #{path.inspect}"
      end
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def open
    @driver = Selenium::WebDriver.for :chrome
    @driver.manage.timeouts.implicit_wait = 10
    @driver.navigate.to @url
    @driver.manage.window.resize_to 500, 800
    # click first x
    game_app = @driver.find_element(:tag_name, 'game-app').shadow_root
    game_modal = game_app.find_element(:tag_name, 'game-modal').shadow_root
    close_icon = game_modal.find_element(:css, 'div.close-icon')
    if close_icon.displayed?
      close_icon.click
    end
    # get rows
    @game_row = game_app.find_elements(:tag_name, 'game-row').map &:shadow_root
    self.inspect
  end

  def close
    @driver.close
  end

  def reopen
    close
    sleep 0.3
    open
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def enter word
    @driver.action.send_keys(word, :enter).perform
  end

  def backspace length
    @driver.action.send_keys([:backspace] * length).perform
  end

  def submit! word
    word = word.to_s
    puts "> #{word}"

    before = matrix.size
    enter word
    after = matrix.size

    if matrix.last.all?(&:invalid?) or before == after
      # It could be "Not enough letters"
      puts %Q`! Not in word list "#{word}"`
      backspace word.length
      @solver.delete_from_dictionary word
      false
    else
      @solver.check matrix.last
      puts %Q`  #{@solver.progress.join('/')}`
      @solver.add_to_dictionary word
      true
    end
  end
  alias :<< :submit!

  def win?
    matrix&.last&.all?(&:green?)
  end

  def remaining
    @game_row.size - matrix.size
  end

  def auto!
    while !@solver.subset.empty? and !win? and remaining.positive?
      submit! @solver.answer
      sleep 1
    end
    nil
  end

  def sample! n=1
    while n.positive? and remaining.positive?
      if submit! @solver.whole.sample
        n -= 1
      end
      sleep 1 unless n.zero?
    end
    @solver.progress
  end
  alias :random! :sample!

  def matrix
    @game_row.map do |r|
      arr = r.find_elements(:tag_name, 'game-tile').map do
        Tile.new(_1.attribute('letter'), _1.attribute('evaluation'))
      end
      arr.all?(&:empty?) ? nil : arr
    end.compact
  end
end

#---

if ARGV.size == 1
  s = Wordle.new ARGV.first
  binding.irb
  # you can try `s.auto!`
else
  puts 'usage:'
  puts "  $ #{$0} (dictionary file)"
  puts
end

