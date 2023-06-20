#!/usr/bin/env ruby

class DayAndHoursGenerator
  require "#{ENV['HOME']}/programming/scripts/formatted_ddate.rb"
  require "#{ENV['HOME']}/programming/scripts/planetary_rulers.rb"

  def self.call
    new.call
  end

  def initialize
    @ddate = FormattedDdate.call
    @planetary_rulers = PlanetaryRulerships.call
  end

  def call
    print "#{ddate} #{rulerships}"
  end

  private
  attr_reader :ddate, :planetary_rulers

  def rulerships
    # uncomment for glyphs rather than text
    # "#{glyph_map[daily_ruler]}/#{glyph_map[hourly_ruler]}"

    "#{daily_ruler}/#{hourly_ruler}"
  end

  def daily_ruler
    planetary_rulers[:daily_ruler].to_s.capitalize
  end

  def hourly_ruler
    planetary_rulers[:hourly_ruler].to_s.capitalize
  end

  def glyph_map
    {
      'Jupiter' => '♃',
      'Luna' => '☽',
      'Mars' => '♂',
      'Mercury' => '☿',
      'Saturn' => '♄',
      'Sol' => '☼',
      'Venus' => '♀'
    }
  end
end

DayAndHoursGenerator.call
