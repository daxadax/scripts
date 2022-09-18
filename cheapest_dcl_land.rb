#!/usr/bin/env ruby
require 'json'

class CheapestDclLand
  def self.call
    new.call
  end

  def initialize
    print "Fetching data...\n"
    tiles_json = `curl -s https://api.decentraland.org/v1/tiles`
    @data = JSON.parse(tiles_json)['data']
  end

  def call
    for_sale = data.select { |_, details| details['type'] == 10 }
    for_sale.sort_by { |(_, details)| details['price'] }.first(10).each do |x|
      print "#{x.last['price']} MANA: #{x.first}\n"
    end
  end

  private
  attr_reader :data
end

CheapestDclLand.call
