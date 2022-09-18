#!/usr/bin/env ruby

class FormattedDdate
  require "#{ENV['HOME']}/programming/scripts/planetary_rulers.rb"

  def self.call
    new.call
  end

  # TODO: test st tibs day output
  def initialize
    @ddate = `ddate +"%{%B %d%}"`
    @planetary_rulers = PlanetaryRulerships.call
  end

  def call
    print "#{formatted_date} #{rulerships}"
  end

  private
  attr_reader :ddate, :planetary_rulers

  def formatted_date
    return ddate if st_tibs_day?

    "#{season_map[season]}/#{day}"
  end

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

  def day
    @day ||= ddate.split.last
  end

  def season
    @season ||= ddate.delete(day).strip
  end

  def st_tibs_day?
    false
  end

  def season_map
    {
      'Chaos' => 1,
      'Discord' => 2,
      'Confusion' => 3,
      'Bureaucracy' => 4,
      'The Aftermath' => 5,
    }
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

FormattedDdate.call
