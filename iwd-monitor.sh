#!/bin/bash

## this is referenced by /etc/systemd/system/iwd-monitor.service
## copy it somewhere on the system path so it doesn't depend on user home paths
## sudo ln -sf ~/programming/scripts/iwd-monitor.sh /usr/local/bin/iwd-monitor

IF=wlan0

# Case 1 — L2 failure: not associated to any AP.
# Symptoms: iwctl shows no "Connected network", often no wlan0 carrier.
# Cause: iwd stuck, driver glitch, AP kicked the client without clean recovery.
# Fix: full iwd restart
if ! iwctl -p off station "$IF" show 2>/dev/null | grep -q 'Connected network'; then
  systemctl restart iwd

# Case 2 — L2 OK, L3 broken: associated but no IPv4 on the interface.
# Symptoms: router may show the client; SLAAC IPv6 may exist; no SSH.
# Cause: iwd's DHCP didn't run or lease was lost while Wi‑Fi stayed up.
# Fix: restart iwd so it re-runs network configuration
elif ! ip -4 addr show dev "$IF" | grep -q 'inet '; then
  systemctl restart iwd

# Case 3 — L2 + L3 OK, path broken: has an IPv4 address but can't reach the internet.
# Symptoms: inet on wlan0, ping to gateway or 8.8.8.8 fails.
# Cause: stale route, DNS, AP isolation, gateway issue — usually not a dead radio.
# Fix: reconnect in place; avoids deauth + full daemon restart unless needed.
elif ! ping -c1 -W3 8.8.8.8 >/dev/null 2>&1; then
  iwctl station "$IF" reconnect
fi
