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
    for_sale = data.select { |_, details| details['type'] == 10 }.values

    estates = for_sale.reject { |details| details['estate_id'].nil? }
    parcels = for_sale - estates


    print "\n"
    print "#estates\n"
    estates.group_by { |details| details['estate_id'] }.
            sort_by { |id, parcels| parcels[0]['price'] / parcels.count.to_f.round }.
            first(10).each do |id, parcels|
              total_price = parcels[0]['price']
              per_parcel = total_price / parcels.count.to_f.round
              print "#{per_parcel} MANA per parcel: #{total_price} MANA, #{parcels.count} parcels, id: #{id}\n"
            end

    print "\n"
    print "#parcels\n"
    parcels.sort_by { |details| details['price'] }.first(10).each do |x|
      print "#{x['price']} MANA: #{x['x']}, #{x['y']}\n"
    end

    @data = nil
  end

  private
  attr_accessor :data
end

CheapestDclLand.call
