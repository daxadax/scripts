#!/usr/bin/env ruby

# modified from https://gist.github.com/pbock/3ab260f3862c350e6b5f #

require 'watir-webdriver'

class BurgerBot

  def initialize
    @attempt_count = 0
    @date = Time.now.to_i
  end

  def run
    until appointment_available?
    puts 'Sleeping.'
    sleep 30
    end
  end

  private

  def appointment_available?
    puts '-'*80
    puts "Beginning attempt ##{@attempt_count += 1}"
    browser.goto url
    puts 'Page loaded'
    link = browser.element css: '.calendar-month-table:first-child td.buchbar a'
    if link.exists? # only show links once?
      link.click
      notify 'An appointment is available.'
      puts 'Enter y to keep searching or anything else to quit.'
      return gets.chomp.downcase != 'y'
    else
      puts 'No luck this time.'
      return false
    end
  rescue StandardError => e
    puts 'Error encountered.'
    puts e.inspect
    return false
  end

  def browser
    @browser ||= Watir::Browser.new :chrome
  end

  def notify(message)
    puts message.upcase
    system 'LANG=C xmessage -nearmouse "%s"' % message
    rescue StandardError => e
  end

  def url
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

BurgerBot.new.run
