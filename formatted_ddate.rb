#!/usr/bin/env ruby

class FormattedDdate
  def self.call
    new.call
  end

  # TODO: test st tibs day output
  def initialize
    @ddate = `ddate +"%{%B %d%}"`
  end

  def call
    formatted_date
  end

  private
  attr_reader :ddate

  def formatted_date
    return ddate if st_tibs_day?

    "#{season_map[season]}/#{day}"
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
end
