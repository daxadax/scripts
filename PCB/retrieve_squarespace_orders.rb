require 'faraday'
require 'pry'

class RetrieveSquarespaceOrders
  API_VERSION = '1.0'
  API_KEY = ENV['PCB_SQUARESPACE_ORDERS_API_KEY']
  URL = "https://api.squarespace.com/#{API_VERSION}/commerce/orders"

  CANCELLED_STATUS = 'CANCELED'
  PENDING_STATUS = 'PENDING'

  def self.call
    new.call
  end

  def call
    conn = Faraday.new(URL) do |conn|
      conn.request :authorization, 'Bearer', API_KEY
    end

    response = conn.get
    result = JSON.parse(response.body)['result']

    # Write to file
    # File.open('PCB-orders.json', 'w+') { |f| f.write(result.to_json) }
    # Read from file
    # result = JSON.parse(File.read('PCB-orders.json'))

    current = result.flat_map do |r|
      ordered_at = r['createdOn']

      # made after the most recent delivery day
      next unless made_after_most_recent_delivery?(ordered_at)

      # fulfillment is pending (not cancelled)
      next if r['fulfillmentStatus'] != PENDING_STATUS

      build_orders(r['lineItems']).map do |order|
        order.
          merge(r['shippingAddress'].transform_keys(&:to_sym)).
          merge(
            ordered_at: ordered_at,
            order_number: r['orderNumber'],
            email: r['customerEmail'],
            delivery_instructions: fetch_delivery_instructions(r['formSubmission']),
          )
      end
    end.compact
  end

  private

  def made_after_most_recent_delivery?(str)
    timestamp = DateTime.parse(str)

    # Find the most recent Monday at noon (UTC)
    now = Time.now.utc.to_datetime
    days_since_monday = now.wday == 0 ? 6 : now.wday - 1  # Sunday = 0, Monday = 1
    seconds_since_cutoff = 60 * 60 * 24 * days_since_monday
    most_recent_monday_noon = Time.utc(now.year, now.month, now.day, 12) - seconds_since_cutoff

    timestamp > most_recent_monday_noon.to_datetime
  end

  def build_orders(items)
    items.map do |i|
      options = i['variantOptions'].map { |o| [o['optionName'], o['value']] }.to_h

      {
        order_type: i['productName'],
        order_quantity: i['quantity'],
        customizations: i['customizations']
      }.merge(options)
    end
  end

  def fetch_delivery_instructions(form_data)
    return if form_data.nil?

    form_data.map do |data|
      [data['label'], data['value']]
    end.to_h['Delivery instructions']
  end
end
