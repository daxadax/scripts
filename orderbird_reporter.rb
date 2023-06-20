#!/usr/bin/env ruby

# modified from https://gist.github.com/pbock/3ab260f3862c350e6b5f #

require 'faraday'
require 'pry'

class OrderbirdReporter
  LOGIN_EMAIL = ENV['ORDERBIRD_LOGIN']
  LOGIN_PASSWORD = ENV['ORDERBIRD_PASSWORD']
  USER_AGENT = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36'

  def initialize
    @url = 'https://my.orderbird.com'
    # @url = 'https://nowsecure.nl/'
  end

  def run
  end

  private

  def fetch_proxy
    proxies = []
    browser = Selenium::WebDriver.for(:chrome)
    browser.get('https://www.sslproxies.org')

    elements = browser.find_element(css: 'table tbody tr').text
    browser.close

    elements.split.first(2).join(':')
  end
end

OrderbirdReporter.new.run
