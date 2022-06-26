#! /usr/bin/env ruby

require_relative 'solver.rb'
require 'webdrivers/chromedriver'

class WordHurdle
  attr_reader :driver, :url, :solver

  def initialize path, url='https://solitaired.com/wordhurdle'
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
    @driver.manage.window.resize_to 500, 780
    game_area = @driver.find_element(:css, 'div.game_area')
    # get rows
    @game_row = game_area.find_elements(:css, 'div.wordhunt-row')
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

    sleep 1.5

    if matrix.last.all?(&:invalid?) or before == after
      # It could be "Not enough letters"
      puts %Q`! Not in word list: #{word.inspect}`
      sleep 0.5
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
      arr = r.find_elements(css: 'div.row_block').map do
        t = _1.text
        t = nil if t.empty?
        c = _1.attribute(:class).split
        s = case
            when c.include?('blockGreen') then :green
            when c.include?('blockGold')  then :yellow
            when c.include?('blockGrey')  then :black
            end
        Tile.new(t, s)
      end
      arr.all?(&:empty?) ? nil : arr
    end.compact
  end
end

#---

if __FILE__ == $0
  d = ARGV.empty? ? File.basename($0, '.*') + '.dic' : ARGV.first
  s = WordHurdle.new d
  binding.irb
  # you can try `s.auto!`
end

