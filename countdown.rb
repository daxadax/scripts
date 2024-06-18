require 'time'

datetime = Time.parse('2024-06-17 18:25+02:00')
result = ((datetime - Time.now.localtime) / 3600).round(2)
hours, minutes_percent = result.to_s.split('.')
minutes_percent = "0.#{minutes_percent}".to_f
minutes = (minutes_percent * 60).round

p "#{hours}시 #{minutes}분"
