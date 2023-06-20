#!/usr/bin/env ruby

require "#{ENV['HOME']}/programming/scripts/moon_info.rb"
require 'json'
require 'date'

class Forecaster
  URL = 'https://api.openweathermap.org/data/3.0/onecall'
  API_KEY = ENV['OPENWEATHER_API_KEY']

  def self.call(latitude, longitude)
    new(latitude, longitude).call
  end

  def initialize(latitude, longitude)
    @latitude = latitude
    @longitude = longitude
  end

  def call
    build_structure(fetch_forecast)
  end

  private
  attr_reader :latitude, :longitude

  def build_structure(forecast)
    current = {
      temp: forecast['current']['temp'],
      desc: forecast['current']['weather'][0]['description'],
      icon_url: icon_url(forecast['current']['weather'][0]['icon'])
    }

    daily = forecast['daily'].map do |day|
      {
        date: Time.at(day['dt']).to_date.to_s,
        sunrise: Time.at(day['sunrise']).strftime("%H:%M"),
        sunset: Time.at(day['sunset']).strftime("%H:%M"),
        moon_info: MoonInfo.new(day['moon_phase']),
        uvi: day['uvi'],
        uv_risk: risk_from_uv(day['uvi']),
        min_temp: day['temp']['min'],
        max_temp: day['temp']['max'],
        desc: day['weather'][0]['description'],
        icon_url: icon_url(day['weather'][0]['icon'])
      }
    end

    OpenStruct.new(current: current, daily: daily)
  end

  def risk_from_uv(uvi)
    case uvi
    when 0..2 then 'low'
    when 2..5 then 'moderate'
    when 5..7 then 'high'
    when 7..10 then 'very_high'
    else
      'extreme'
    end
  end

  def fetch_forecast
    url = URL
    url += "?lat=#{latitude}"
    url += "&lon=#{longitude}"
    url += "&appid=#{API_KEY}"
    url += "&units=metric"
    url += "&exclude=minutely,hourly"

    JSON.parse(`curl -s '#{url}'`)
  end

  def icon_url(icon)
    "https://openweathermap.org/img/wn/#{icon}@2x.png"
  end
end
