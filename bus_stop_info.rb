#!/usr/bin/env ruby

require 'json'
require 'date'

class BusStopInfo
  def self.options_at_location(location, line = nil)
    result = `curl -s 'https://v6.bvg.transport.rest/locations?query=#{location}&results=1'`
    data = JSON.parse(result)[0]

    return [] if data.nil?
    new(data['id'], data['name'], line).call
  end

  def self.print_to_terminal(trip)
    density = ''
    if trip[:density]
      density = case trip[:density]
                when 'low' then ' - empty'
                when 'medium' then ' - average'
                when 'high' then ' - crowded'
                end
    end

    arriving_in = trip[:arrives_in].zero? ? "now" : "#{trip[:arrives_in]} min"

    str = "[#{arriving_in}#{density}] #{trip[:name]} #{trip[:direction]}"
    str += " on platform #{trip[:platform]}" if trip[:platform]

    print str + "\n"
  end

  def initialize(stop_id, name, line = nil)
    @stop_id = stop_id
    @stop_name = name
    @line = line
  end

  def call
    data = `curl -s 'https://v6.bvg.transport.rest/stops/#{stop_id}/departures'`

    JSON.parse(data)['departures'].map do |trip|
      next if line && trip['line']['name'].downcase != line.downcase
      next if trip['direction'] == 'Fahrt endet hier'

      arrival = trip['when'] || trip['plannedWhen']
      next unless arrival

      arrives_at = DateTime.parse(arrival).to_time
      arrival_min = (arrives_at - Time.now) / 60
      next if arrival_min.negative?


      {
        arrives_in: arrival_min.round,
        arrives_at: arrives_at.to_s,
        arrives_at_int: arrives_at.to_i,
        mode: trip['line']['mode'],
        name: trip['line']['name'],
        direction: trip['direction'],
        platform: trip['platform'],
        density: trip['occupancy']
      }
    end.compact
  end

  private
  attr_reader :line, :stop_id, :stop_name
end

if ENV['BVG_TARGET'] == 'stdout'
  if ARGV.any?
  result = BusStopInfo.options_at_location(*ARGV)

  # TODO: use option parser
    if result.any?
      print "\n"
      result.each { |trip| BusStopInfo.print_to_terminal(trip) }
      print "\n"
    else
      print "\nYour query didn't return a result\n"
    end
  else
    print "Please call 'ruby bus_stop_info.rb LOCATION LINE(optional)'\n"
  end
end
