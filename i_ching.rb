#!/usr/bin/env ruby

#
# The I Ching is not magic;
# it is science that we don’t understand.
# - Terence McKenna
#

class IChing
  def self.call
    new.call
  end

  def initialize
    @result = {}
    @hexagram_map = hexagram_mapping.freeze
  end

  def call
    result[:lower_lines]    = 3.times.map { calculate_line }
    result[:lower_trigram]  = determine_trigram(result[:lower_lines])

    result[:upper_lines]    = 3.times.map { calculate_line }
    result[:upper_trigram]  = determine_trigram(result[:upper_lines])

    result[:hexagram]        = determine_hexagram(result)

    output = "HEXAGRAM #{result[:hexagram]}: "
    output += "#{result[:upper_trigram].last.upcase} "
    output += "over "
    output += "#{result[:lower_trigram].last.upcase}\n"
    output += "https://www.jamesdekorne.com/GBCh/hex#{result[:hexagram]}.htm\n"

    print output
    result
  end

  private
  attr_accessor :result
  attr_reader :hexagram_map

  def calculate_line
    d20 = roll_d20

    return '___' if d20.odd?
    '_ _'
  end

  def determine_trigram(lines)
    return ['☰', 'heaven']    if lines.all? { |line| line == '___' }
    return ['☷', 'earth']     if lines.all? { |line| line == '_ _' }
    return ['☱', 'lake']      if lines.first(2) == ['___', '___']
    return ['☶', 'mountain']  if lines.first(2) == ['_ _', '_ _']
    return ['☳', 'thunder']   if lines.last(2) == ['_ _', '_ _']
    return ['☴', 'wind']      if lines.last(2) == ['___', '___']
    return ['☲', 'fire']      if lines.first == '___'
    return ['☵', 'water']     if lines.first == '_ _'
  end

  def determine_hexagram(hash)
    hexagram_map.dig(hash[:lower_trigram].last, hash[:upper_trigram].last)
  end

  def roll_d20
    Random.rand(1..20)
  end

  def roll_d8
    Random.rand(1..8)
  end

  def hexagram_mapping
    {
      'heaven' => {
        'heaven' => 1,
        'thunder' => 34,
        'water' => 5,
        'mountain' => 26,
        'earth' => 11,
        'wind' => 9,
        'fire' => 14,
        'lake' => 43
      },
      'thunder' => {
        'heaven' => 25,
        'thunder' => 51,
        'water' => 3,
        'mountain' => 27,
        'earth' => 24,
        'wind' => 42,
        'fire' => 21,
        'lake' => 17
      },
      'water' => {
        'heaven' => 6,
        'thunder' => 40,
        'water' => 29,
        'mountain' => 4,
        'earth' => 7,
        'wind' => 59,
        'fire' => 64,
        'lake' => 47
      },
      'mountain' => {
        'heaven' => 33,
        'thunder' => 62,
        'water' => 39,
        'mountain' => 52,
        'earth' => 15,
        'wind' => 53,
        'fire' => 56,
        'lake' => 31
      },
      'earth' => {
        'heaven' => 12,
        'thunder' => 16,
        'water' => 8,
        'mountain' => 23,
        'earth' => 2,
        'wind' => 20,
        'fire' => 35,
        'lake' => 45
      },
      'wind' => {
        'heaven' => 44,
        'thunder' => 32,
        'water' => 48,
        'mountain' => 18,
        'earth' => 46,
        'wind' => 57,
        'fire' => 50,
        'lake' => 28
      },
      'fire' => {
        'heaven' => 13,
        'thunder' => 55,
        'water' => 63,
        'mountain' => 22,
        'earth' => 36,
        'wind' => 37,
        'fire' => 30,
        'lake' => 49
      },
      'lake' => {
        'heaven' => 10,
        'thunder' => 54,
        'water' => 60,
        'mountain' => 41,
        'earth' => 19,
        'wind' => 61,
        'fire' => 38,
        'lake' => 58
      }
    }
  end
end

IChing.call
