#!/usr/bin/env ruby

require "#{ENV['HOME']}/programming/scripts/moon_info.rb"
require "#{ENV['HOME']}/programming/scripts/moon_phase_for_date.rb"
require 'json'
require 'date'

class Forecaster
  BASE_URL = 'https://api.openweathermap.org/data'
  ONECALL_URL = "#{BASE_URL}/3.0/onecall"
  ONECALL_HISTORIC_URL = "#{BASE_URL}/3.0/onecall/timemachine"
  AIR_QUALITY_URL = "#{BASE_URL}/2.5/air_pollution"
  API_KEY = ENV['OPENWEATHER_API_KEY']

  def self.call(latitude, longitude)
    new(latitude, longitude).call
  end

  def self.historic(latitude, longitude, timestamp)
    new(latitude, longitude, timestamp).call_historic
  end

  def initialize(latitude, longitude, timestamp = nil)
    @latitude = latitude
    @longitude = longitude
    @timestamp = timestamp
    @air_quality = fetch_air_quality #TODO: also problem for historic
  end

  def call
    @forecast = fetch_forecast(ONECALL_URL)

    build_structure(@forecast, @air_quality)
  end

  def call_historic
    @forecast = fetch_forecast(ONECALL_HISTORIC_URL)

    build_historic_structure(@forecast)
  end

  private
  attr_reader :latitude, :longitude, :timestamp

  def build_structure(forecast, air_quality)
    current = {
      air_quality: quantify_air_quality(air_quality['list'][0]['main']['aqi']),
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

  def build_historic_structure(forecast)
    data = forecast['data'][0]
    date = Time.at(data['dt']).to_date.to_s

    {
      date: date,
      sunrise: Time.at(data['sunrise']).strftime("%H:%M"),
      sunset: Time.at(data['sunset']).strftime("%H:%M"),
      moon_phase: MoonPhaseForDate.call(date: date),
      uvi: data['uvi'],
      uv_risk: risk_from_uv(data['uvi']),
      temp: data['temp'],
      desc: data['weather'][0]['description']
    }
  end

  def quantify_air_quality(aqi)
    case aqi
    when 1 then 'good'
    when 2 then 'fair'
    when 3 then 'moderate'
    when 4 then 'poor'
    when 5 then 'bad'
    else
      'extreme'
    end
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

  def fetch_air_quality
    url = AIR_QUALITY_URL
    url += "?lat=#{latitude}"
    url += "&lon=#{longitude}"
    url += "&appid=#{API_KEY}"

    JSON.parse(`curl -s '#{url}'`)
  end

  def fetch_forecast(url)
    url = url
    url += "?lat=#{latitude}"
    url += "&lon=#{longitude}"
    url += "&dt=#{timestamp}" if timestamp
    url += "&appid=#{API_KEY}"
    url += "&units=metric"
    url += "&exclude=minutely,hourly"

    JSON.parse(`curl -s '#{url}'`)
  end

  def icon_url(icon)
    "https://openweathermap.org/img/wn/#{icon}@2x.png"
  end
end
