# used in ~/.config/i3/config
# bindsym --release $mod+$super+Ctrl+space exec ruby ~/programming/scripts/switch_keyboard_layout.rb


current_engine = `ibus engine`.strip
toggle_engine = current_engine == 'hangul' ? 'xkb:us::eng' : 'hangul'

# tell ibus to update the engine
system("ibus engine #{toggle_engine}")

# send real-time signal #7 to i3blocks to update keyboard layout block
system('pkill -SIGRTMIN+7 i3blocks')

# send a notification
friendly = toggle_engine == 'hangul' ? 'Korean' : 'English'
two_letter = toggle_engine == 'hangul' ? 'ko' : 'en'
# TODO: would be nice to send a flag with the notification
# system("notify-send -a keyboard-layout -t 1000 'Using #{friendly} keyboard layout' -i '~/programming/scripts/resources/#{two_letter}.png'")
system("notify-send -a keyboard-layout -t 1000 'Using #{friendly} keyboard layout'")
