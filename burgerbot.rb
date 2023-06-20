#!/usr/bin/env ruby

# modified from https://gist.github.com/pbock/3ab260f3862c350e6b5f #

require 'selenium-webdriver'
require 'date'
require 'pry'

class BurgerBot
  def initialize(termin_type)
    today = Date.today

    @attempt_count = 0
    @date = Date.new(today.year, today.month, 1)
    @url = determine_url(termin_type)
  end

  def run
    until appointment_available?
      puts 'Sleeping.'
      sleep 35
    end
  end

  private

  def appointment_available?
    puts '-'*80
    puts "Beginning attempt ##{@attempt_count += 1}"
    browser.get @url
    puts 'Page loaded'
    link = browser.find_element(css: '.buchbar a')
    link.click
    notify 'An appointment is available.'
    puts 'Enter y to keep searching or anything else to quit.'
    return gets.chomp.downcase != 'y'
  rescue Selenium::WebDriver::Error::NoSuchElementError => e
    puts 'No luck this time.'
    return false
  rescue StandardError => e
    puts 'Error encountered.'
    puts e.inspect
    return false
  end

  def determine_url(termin_type)
    case termin_type
    when 'anmeldung' then anmeldung_url
    when 'background_check' then background_check_url
    when 'gewerbe' then gewerbe_registration_url
    else
      raise ArgumentError, "Unknown termin type: #{termin_type}"
    end
  end

  def browser
    @browser ||= Selenium::WebDriver.for :chrome
  end

  def notify(message)
    puts message.upcase
    `notify-send "#{message}"`
    `spd-say -t male3 -p -23 -r -23 "I've found an appointment"`
    rescue StandardError => e
  end

  def background_check_url
    'https://service.berlin.de/terminvereinbarung/termin/tag.php?'\
    'termin=1&'\
    'anliegen[]=120926&'\
    'dienstleisterlist=122210,122217,122219,122227,122231,122238,122243,122254,331011,349977,122252,122260,122262,122271,122273,122277,122280,122282,122284,122291,122285,122286,122296,150230,122297,122294,122312,122314,122304,122311,122309,317869,122281,122279,122283,122276,122274,122267,122246,122251,122257,122208,122226&'\
    'herkunft=http%3A%2F%2Fservice.berlin.de%2Fdienstleistung%2F120926%2F'
  end

  def gewerbe_registration_url
    'https://service.berlin.de/terminvereinbarung/termin/tag.php?'\
    'termin=1&'\
    'anliegen[]=327835&'\
    'dienstleisterlist=122210,122217,122219,122227,122231,122238,122243,122254,331011,349977,122252,122260,122262,122271,122273,122277,122280,122282,122284,122291,122285,122286,122296,324759,150230,122297,122294,122312,122314,122304,122311,122309,317869,122281,122279,122283,122276,122274,122267,122246,122251,122257,122208,122226&'\
    'herkunft=http%3A%2F%2Fservice.berlin.de%2Fdienstleistung%2F327835%2F'
  end

  def anmeldung_url
    'https://service.berlin.de/terminvereinbarung/termin/tag.php'\
    '?id=&buergerID=&buergername=&absagecode='\
    "&Datum=#{@date}"\
    '&anliegen%5B%5D=120686'\
    '&dienstleister%5B%5D=122210'\
    '&dienstleister%5B%5D=122217'\
    '&dienstleister%5B%5D=122219'\
    '&dienstleister%5B%5D=122227'\
    '&dienstleister%5B%5D=122231'\
    '&dienstleister%5B%5D=122243'\
    '&dienstleister%5B%5D=122252'\
    '&dienstleister%5B%5D=122260'\
    '&dienstleister%5B%5D=122262'\
    '&dienstleister%5B%5D=122254'\
    '&dienstleister%5B%5D=122271'\
    '&dienstleister%5B%5D=122273'\
    '&dienstleister%5B%5D=122277'\
    '&dienstleister%5B%5D=122280'\
    '&dienstleister%5B%5D=122282'\
    '&dienstleister%5B%5D=122284'\
    '&dienstleister%5B%5D=122285'\
    '&dienstleister%5B%5D=122286'\
    '&dienstleister%5B%5D=122296'\
    '&dienstleister%5B%5D=150230'\
    '&dienstleister%5B%5D=122301'\
    '&dienstleister%5B%5D=122297'\
    '&dienstleister%5B%5D=122294'\
    '&dienstleister%5B%5D=122312'\
    '&dienstleister%5B%5D=122314'\
    '&dienstleister%5B%5D=122304'\
    '&dienstleister%5B%5D=122311'\
    '&dienstleister%5B%5D=122309'\
    '&dienstleister%5B%5D=317869'\
    '&dienstleister%5B%5D=324433'\
    '&dienstleister%5B%5D=325341'\
    '&dienstleister%5B%5D=324434'\
    '&dienstleister%5B%5D=122281'\
    '&dienstleister%5B%5D=324414'\
    '&dienstleister%5B%5D=122283'\
    '&dienstleister%5B%5D=122279'\
    '&dienstleister%5B%5D=122276'\
    '&dienstleister%5B%5D=122274'\
    '&dienstleister%5B%5D=122267'\
    '&dienstleister%5B%5D=122246'\
    '&dienstleister%5B%5D=122251'\
    '&dienstleister%5B%5D=122257'\
    '&dienstleister%5B%5D=122208'\
    '&dienstleister%5B%5D=122226'
  end
end

print "Which kind of appointment do you need?\n\n1. Anmeldung\n2. Background Check\n3. Gerwerbe Registration\n"
input = gets.chomp.to_i

termin_type = case input
              when 1 then 'anmeldung'
              when 2 then 'background_check'
              when 3 then 'gewerbe'
              end

`clear`
BurgerBot.new(termin_type).run
