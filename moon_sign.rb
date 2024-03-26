# Translated into ruby from www.astrocal.co.uk/apps/moonsign/moon.js

class MoonSign
  attr_reader :sign

  OBLIQUITY_BASE = 23.452294

  def initialize(time)
    @sign = calculate_sign(time)
  end

  def symbol
    symbol_map[sign]
  end

  def degree
    @degree # set in #calculate_sign
  end

  private

  def calculate_sign(time)
    julian_day = time.to_date.jd

    zone = time.gmt_offset
    f = time.hour + (time.min / 60.to_f) + (zone / 3600.to_f)
    t = ((julian_day - 2415020)+ f/24-0.5) / 36525.to_f
    ll = 973563+ 1732564379*t- 4*t*t
    g = 1012395+ 6189*t
    n = 933060- 6962911*t+ 7.5*t*t
    g1 = 1203586+ 14648523*t- 37*t*t
    d = 1262655+ 1602961611*t- 5*t*t
    l = (ll- g1) / 3600.to_f
    l1 = ((ll- d)- g) / 3600.to_f
    f = (ll- n) / 3600
    d = d / 3600
    y = 2*d
    ml = 22639.6*FNs(l)- 4586.4*FNs(l- y)
    ml = ml + 2369.9*FNs(y)+ 769*FNs(2*l)- 669*FNs(l1)
    ml = ml - 411.6*FNs(2*f)- 212*FNs(2*l- y)
    ml = ml - 206*FNs(l+ l1- y)+ 192*FNs(l+ y)
    ml = ml - 165*FNs(l1- y)+ 148*FNs(l- l1)- 125*FNs(d)
    ml = ml - 110*FNs(l+ l1)- 55*FNs(2*f- y)
    ml = ml - 45*FNs(l+ 2*f)+ 40*FNs(l- 2*f)
    tn = n + 5392*FNs(2*f- y)- 541*FNs(l1)- 442*FNs(y)
    tn = tn + 423*FNs(2*f)- 291*FNs(2*l- 2*f)
    g = FNu(FNp(ll+ ml))
    sign = (g/30).floor
    @degree = (g-(sign*30))
    sign = sign+1

    case sign
      when 1 then 'Aries'
      when 2 then 'Taurus'
      when 3 then 'Gemini'
      when 4 then 'Cancer'
      when 5 then 'Leo'
      when 6 then 'Virgo'
      when 7 then 'Libra'
      when 8 then 'Scorpio'
      when 9 then 'Sagittarius'
      when 10 then 'Capricorn'
      when 11 then 'Aquarius'
      when 12 then 'Pisces'
    end
  end

  def symbol_map
    {
      'Aries' => '♈',
      'Taurus' => '♉',
      'Gemini' => '♊',
      'Cancer' => '♋',
      'Leo' => '♌',
      'Virgo' => '♍',
      'Libra' => '♎',
      'Scorpio' => '♏',
      'Sagittarius' => '♐',
      'Capricorn' => '♑',
      'Aquarius' => '♒',
      'Pisces' => '♓'
    }
  end

  # unused?
  def obliquity(time)
    radians(OBLIQUITY_BASE - 0.0130125*time.to_i)
  end

  def FNp(x)
    if(x<0)
      sgn=-1
    else
      sgn=1
    end

    sgn*((x.abs/ 3600) / 360 - ((x.abs / 3600) / 360).floor) * 360
  end

  def FNu(x)
    x-((x/360).floor*360)
  end

  def radians(x)
    Math::PI / 180*x
  end

  def FNs(x)
    Math.sin(radians(x))
  end
end
