current_engine = `ibus engine`.strip
toggle_engine = current_engine == 'hangul' ? 'xkb:us::eng' : 'hangul'

# tell ibus to update the engine
system("ibus engine #{toggle_engine}")

# send real-time signal #7 to i3blocks to update keyboard layout block
system('pkill -SIGRTMIN+7 i3blocks')
