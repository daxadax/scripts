#!/usr/bin/env ruby

require 'json'
require 'date'

class BusStopInfo
  def self.options_at_location(location, line = nil)
    result = `curl -s 'https://v5.bvg.transport.rest/locations?query=#{location}&results=1'`
    data = JSON.parse(result)[0]

    new(data['id'], data['name'], line).call
  end

  def initialize(stop_id, name, line = nil)
    @stop_id = stop_id
    @stop_name = name
    @line = line
  end

  def call
    data = `curl -s 'https://v5.bvg.transport.rest/stops/#{stop_id}/departures'`

    result = JSON.parse(data).map do |trip|
      next if line && trip['line']['name'].downcase != line.downcase
      next if trip['direction'] == 'Fahrt endet hier'

      arrivingAt = trip['when'] || trip['plannedWhen']
      next unless arrivingAt

      arrival = (DateTime.parse(arrivingAt).to_time - Time.now) / 60
      next if arrival.negative?

      {
        arrives_in: arrival.round,
        mode: trip['line']['mode'],
        name: trip['line']['name'],
        direction: trip['direction'],
        platform: trip['platform'],
        density: trip['occupancy']
      }
    end.compact

    if result.any?
      print "#{stop_name}\n"
      result.each { |trip| print_to_terminal(trip) }
    else
      print "Your query didn't return a result.\n"
    end
  end

  private
  attr_reader :line, :stop_id, :stop_name

  def print_to_terminal(trip)
    str = "[#{trip[:arrives_in]}min] #{trip[:name]} #{trip[:direction]}"


    str += " on platform #{trip[:platform]}" if trip[:platform]

    if trip[:density]
      density = case trip[:density]
                when 'low' then 'empty'
                when 'medium' then 'average'
                when 'high' then 'crowded'
                end

      str += " [#{density}]"
    end

    print str + "\n"
  end
end

if ARGV.any?
  BusStopInfo.options_at_location(*ARGV)
else
  print "Please call 'ruby bus_stop_info.rb LOCATION LINE(optional)'\n"
end
