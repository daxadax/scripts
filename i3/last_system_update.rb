require 'time'

last_update = `awk '/pacman -Syu/ {print $1" "$2}' /var/log/pacman.log | tail -n 1 | cut -c 2-17`
last_update_at = Time.parse(last_update)
result = ((Time.now.localtime - last_update_at) / 3600).round(2)
hours, _minutes_percent = result.to_s.split('.')

if hours.to_i > 72
  p "SYSTEM OUTDATED"
end
