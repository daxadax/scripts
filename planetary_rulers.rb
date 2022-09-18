#!/usr/bin/env ruby

require 'date'
require 'faraday'
require 'json'

class PlanetaryRulerships
  DAYS = %i[sol luna mars mercury jupiter venus saturn].freeze
  HOURS = %i[luna saturn jupiter mars sol venus mercury].freeze
  LOCATION = "Berlin, Germany".freeze
  TIMEZONE = Time.now.zone
  # https://app.ipgeolocation.io/
  API_HOST = 'https://api.ipgeolocation.io/astronomy'
  API_KEY = ENV["IPGEOLOCATION_API_KEY"]

  def self.call(timestamps: {})
    new(timestamps).call
  end

  def initialize(timestamps)
    @now = DateTime.now

    if timestamps.empty? || now > timestamps[:next_sunrise]
      set_timestamps
    else
      @last_sunrise = timestamps[:last_sunrise]
      @next_sunrise = timestamps[:next_sunrise]
      @sunset = timestamps[:sunset]
    end
  end

  def call
    print "#{daily_ruler}/#{planetary_hour}\n"

    {
      daily_ruler: daily_ruler,
      hourly_ruler: planetary_hour
    }
  end

  private
  attr_reader :now, :last_sunrise, :next_sunrise, :sunset

  def daily_ruler
    # if last_sunrise is yesterday and hm...?
    DAYS[last_sunrise.wday]
  end

  def planetary_hour
    daily_hours[calculated_hour % 7]
  end

  def daily_hours
    @daily_hours ||= HOURS.rotate(HOURS.index(daily_ruler))
  end

  def timestamps
    {
      last_sunrise: last_sunrise,
      next_sunrise: next_sunrise,
      sunset: sunset
    }
  end

  def calculated_hour
    if daytime?
      (diff_in_minutes(now, last_sunrise) / hour_length).floor
    else
      (diff_in_minutes(now, sunset) / hour_length).floor + 12
    end
  end

  def hour_length
    diff = if daytime?
             diff_in_minutes(sunset, last_sunrise)
           else
             diff_in_minutes(sunset, next_sunrise)
           end

    (diff / 12).abs
  end

  def daytime?
    now < sunset
  end

  def day_of_the_week
    return now.wday if after_sunrise?

    (now.wday - 1) % 7
  end

  def after_sunrise?
    return true if now.hour > last_sunrise.hour

    (now.hour == last_sunrise.hour && now.min > last_sunrise.min)
  end

  def diff_in_minutes(date_a, date_b)
    (date_a - date_b) / 60
  end

  def set_timestamps
    # fetch data for today
    today = fetch_data

    #@now = build_local_timestamp(today['date'], today['current_time'])
    sunrise = build_local_timestamp(today['date'], today['sunrise'])

    if now < sunrise
      # fetch yesterdays data
      yesterday = fetch_data((Date.today - 1).iso8601)

      # set todays data as next sunrise
      @next_sunrise = sunrise

      # set yesterdays data as last sunrise and sunset
      @last_sunrise = build_local_timestamp(yesterday['date'], yesterday['sunrise'])
      @sunset = build_local_timestamp(yesterday['date'], yesterday['sunset'])
    else
      # fetch tomorrows data
      tomorrow = fetch_data((Date.today + 1).iso8601)

      # set tomorrows data as next sunrise
      @next_sunrise = build_local_timestamp(tomorrow['date'], tomorrow['sunrise'])

      # set todays data as last sunrise and sunset
      @last_sunrise = build_local_timestamp(today['date'], today['sunrise'])
      @sunset = build_local_timestamp(today['date'], today['sunset'])
    end
  end

  def build_local_timestamp(date, time)
    DateTime.parse("#{date} #{time}#{TIMEZONE}")
  end

  def fetch_data(date = nil)
    params = {
      apiKey: API_KEY,
      location: LOCATION
    }

    params[:date] = date if date

    response = Faraday.get(API_HOST, params)
    JSON.parse(response.body)
  end
end

PlanetaryRulerships.call

