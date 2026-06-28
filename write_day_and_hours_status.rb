#!/usr/bin/env ruby

class WriteDayAndHoursStatus
  require "#{ENV['HOME']}/programming/scripts/formatted_ddate.rb"
  require "#{ENV['HOME']}/programming/scripts/planetary_rulers.rb"

  def self.call(target_dir = "#{ENV['HOME']}/.status")
    new(target_dir).call
  end

  def initialize(target_dir)
    @ddate = FormattedDdate.call
    @planetary_rulers = PlanetaryRulerships.call
    @target_dir = target_dir
  end

  def call
    File.open("#{target_dir}/ddate", 'w+') { |f| f.write(ddate) }
    File.open("#{target_dir}/rulers-name", 'w+') { |f| f.write(rulerships_name) }
    File.open("#{target_dir}/rulers-glyph", 'w+') { |f| f.write(rulerships_glyph) }
  end

  private
  attr_reader :ddate, :planetary_rulers, :target_dir

  def rulerships_name
    "#{daily_ruler}/#{hourly_ruler}"
  end

  def rulerships_glyph
    "#{glyph_map[daily_ruler]}/#{glyph_map[hourly_ruler]}"
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

WriteDayAndHoursStatus.call
