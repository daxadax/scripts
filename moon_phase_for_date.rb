require 'faraday'

class MoonPhaseForDate
  URL = "https://everydaycalculation.com/moon-phase.php?ajax=1"

  def self.call(date:)
    new(date).call
  end

  def initialize(date)
    date = Date.parse(date)

    @year = date.year
    @month = date.month
    @day = date.day
  end

  def call
    data = {:c=>"g", :d=>@day, :m=>@month, :y=>@year}

    response = Faraday.post(URL) do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(data)
    end

    translate_reponse(response.body)
  end

  private

  def translate_reponse(str)
    match = str.match(/<b>.*<\/b>/)
    phase = match[0].sub("<b>", '').sub("</b>", '')

    case phase
    when 'New Moon' then "new"
    when 'Waxing (Young) Crescent' then 'crescent'
    when 'First Quarter' then 'first quarter'
    when 'Waxing Gibbous' then 'gibbous'
    when 'Full Moon' then 'full'
    when 'Waning Gibbous' then 'disseminating'
    when 'Last Quarter' then 'last quarter'
    when 'Waning (Old) Crescent' then 'balsamic'
    else
      phase
    end
  end
end
