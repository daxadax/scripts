#!/usr/bin/env ruby

# modified from https://gist.github.com/pbock/3ab260f3862c350e6b5f #


##################################################
##################################################
# NOTE: due to changes in Berlin's websites,
# this script is currently borked
##################################################
##################################################


require 'selenium-webdriver'
require 'date'
# require 'pry'

class BurgerBot
  CHARLOTTENBURG = [ 122210, 122217, 122219, 122227 ]
  KREUZBERG = [ 122231, 122238, 122243 ]
  LICTENBERG = [ 122252, 122254, 122260, 122262 ]
  MARZAHN = [ 122271, 122273, 122277 ]
  MITTE = [ 122280, 122282, 122284 ]
  NEUKOLLN = [ 122285, 122286, 122291, 122296 ]
  PANKOW = [ 122294, 122297, 122301, 150230 ]
  REINICKENDORF = [ 122304, 122309, 122311, 122312, 122314, 317869 ]
  SPANDAU = [ 122279, 122281, 122283, 324414 ]
  STEGLITZ = [ 122267, 122274, 122276 ]
  TEMPELHOF_SCHOENEBERG = [ 122246, 122251, 122257 ]
  TREPTOW_KOEPENICK = [ 122208, 122226 ]

  def initialize(termin_type)
    today = Date.today

    @attempt_count = 0
    @date = Date.new(today.year, today.month, 1)
    @selected_locations = [KREUZBERG, NEUKOLLN, PANKOW].flatten.join(',')
    @termin_type = termin_type
    @url = determine_url
  end

  def run
    if visa_seeker?
      puts 'Entering kafkaesque nightmare. Hold on to your butts'
      puts '-'*80
      puts "Beginning attempt ##{@attempt_count += 1}"
      browser.get @url
      puts 'Page loaded'
      browser.find_elements(css: 'a').detect { |el| el.text == 'Termin buchen' }.click
      puts 'We\'re in'
      wait = Selenium::WebDriver::Wait.new
      wait.until { browser.find_elements(css: 'input').any?(&:displayed?) }
      checkbox = browser.find_element(css: 'input[name=gelesen]')
      p checkbox
      checkbox.click
      # browser.find_element(css: 'button#applicationForm:managedForm:proceed').click
    else
      until appointment_available?
        puts 'Sleeping.'
        sleep 35
      end
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

  def visa_seeker?
    @termin_type == 'employee_visa'
  end

  def determine_url
    case @termin_type
    when 'anmeldung' then anmeldung_url
    when 'background_check' then background_check_url
    when 'gewerbe' then gewerbe_registration_url
    when 'employee_visa' then employee_visa_url
    else
      raise ArgumentError, "Unknown termin type: #{@termin_type}"
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
    "dienstleisterlist=#{@selected_locations}&"\
    'herkunft=http%3A%2F%2Fservice.berlin.de%2Fdienstleistung%2F120926%2F'
  end

  def gewerbe_registration_url
    'https://service.berlin.de/terminvereinbarung/termin/tag.php?'\
    'termin=1&'\
    'anliegen[]=327835&'\
    "dienstleisterlist=#{@selected_locations}&"\
    'herkunft=http%3A%2F%2Fservice.berlin.de%2Fdienstleistung%2F327835%2F'
  end

  def anmeldung_url
    'https://service.berlin.de/terminvereinbarung/termin/tag.php'\
    '?id=&buergerID=&buergername=&absagecode='\
    "&Datum=#{@date}"\
    '&anliegen%5B%5D=120686'\
    "&dienstleisterlist=#{@selected_locations}"
  end

  def employee_visa_url
    'https://otv.verwalt-berlin.de/ams/TerminBuchen'
  end
end

print "Which kind of appointment do you need?\n\n1. Anmeldung\n2. Background Check\n3. Gerwerbe Registration\n4. Employee Visa\n"
input = gets.chomp.to_i

termin_type = case input
              when 1 then 'anmeldung'
              when 2 then 'background_check'
              when 3 then 'gewerbe'
              when 4 then 'employee_visa'
              end

`clear`
BurgerBot.new(termin_type).run
