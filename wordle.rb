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

    # click first "Play" button
    play_button = nil
    Selenium::WebDriver::Wait.new(timeout:15).until do
      play_button = @driver.find_element xpath:'//button[@data-testid="Play"]'
      play_button.displayed?
    end
    play_button.click

    # click first X in upper right corner
    close_icon = nil
    Selenium::WebDriver::Wait.new(timeout:15).until do
      close_icon = @driver.find_element xpath:'//*[@data-testid="icon-close"]'
      close_icon.displayed?
    end
    close_icon.click

    # get rows
    @game_row = @driver.find_elements xpath:'//*[@id="wordle-app-game"]/div[1]/div[1]/div'
    ####game_app.find_elements(css:'game-row').map &:shadow_root
    self.inspect
  end

  def close
    @driver.close
  end

  def reopen
    close
    sleep 0.3
    open
    @solver.reset
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def enter word
    @driver.action.send_keys(word, :enter).perform
  end

  def backspace length
    @driver.action.send_keys([:backspace] * length).perform
  end

  def submit! word
    return nil unless alive?
    word = word.to_s
    puts "> #{word}"

    before = matrix.size
    enter word
    after = matrix.size

    if matrix.last.all?(&:invalid?) or before == after
      # It could be "Not enough letters"
      puts %Q`! Not in word list: #{word.inspect}`
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

  def alive?
    !win? and remaining.positive?
  end

  def auto!
    while !@solver.give_up? and alive?
      submit! @solver.answer
      sleep 1
    end
    nil
  end

  def sample! n=1
    while n.positive? and remaining.positive?
      case submit! @solver.whole.sample
      when nil then break
      when true then n -= 1
      end
      sleep 1 unless n.zero?
    end
    @solver.progress
  end
  alias :random! :sample!

  def matrix
    @game_row.map do |r|
      arr = r.find_elements(xpath:'div/div').map do |e|
        if e.text.empty?
          Tile.new nil, nil
        else
          wait = Selenium::WebDriver::Wait.new timeout:5
          wait.until do
            e.attribute('data-animation') == 'idle'
          end
          Tile.new e.text, e.attribute('data-state')
        end
      end
      arr.all?(&:empty?) ? nil : arr
    end.compact
  end
end

#---

if __FILE__ == $0
  d = ARGV.empty? ? File.basename($0, '.*') + '.dic' : ARGV.first
  s = Wordle.new d
  binding.irb
  # you can try `s.auto!`
end

