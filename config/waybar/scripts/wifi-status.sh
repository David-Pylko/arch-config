#!/usr/bin/env bash

if ! command -v iwctl &>/dev/null; then
  echo "{\"text\": \"󰤫\", \"tooltip\": \"iwctl utility is missing\"}"
  exit 1
fi

# Find the name of the active Wi-Fi device
# device_name=$(iw dev | awk '$1=="Interfface" {print $2}')
device_name=$(iwctl device list | grep "on" | awk '{print $2}')

if [ -z "$device_name" ]; then
  echo "{\"text\": \"󰤮\", \"tooltip\": \"Wi-Fi Disabled\"}"
  exit 0
fi

wifi_info=$(iwctl station "$device_name" show)

# check if connected
# If no ESSID is found, set a default value
if echo "$wifi_info" | grep "disconnected"; then
  essid="No Connection"
  signal=0
  tooltip="No Connection"
else
  ip_address="127.0.0.1"
  security=$(echo "$wifi_info" | awk -F: '{print $4}')
  signal=$(echo "$wifi_info" | awk -F: '{print $3}')

    # Get ESSID, signal strength, and security from iwctl output
    essid=$(echo "$wifi_info" | grep "Connected network" | awk '{$1=$2=""; sub(/^[ \t]+/, ""); print}')


    signal_dbm=$(iw dev "$device_name" link | grep "signal" | awk '{print $2}')
    
    # Check if a signal was found
    if [ -z "$signal_dbm" ]; then
        signal=0
    else
        # Convert dBm to a percentage approximation
        # Formula: 2 * (dBm + 100)
        # This is a common heuristic for a signal range of -100dBm (0%) to -50dBm (100%)
        signal=$((2 * (signal_dbm + 100)))
        if [ "$signal" -gt 100 ]; then signal=100; fi
        if [ "$signal" -lt 0 ]; then signal=0; fi
    fi
    
    security=$(echo "$wifi_info" | grep "Security" | awk '{print $2}')
    ip_address=$(ip -4 addr show "$device_name" | grep "inet" | awk '{print $2}' | cut -d/ -f1)
    chan=$(iw dev "$device_name" link | grep "channel" | awk '{print $2 " (" $4 " " $5 ")"}')

    # Construct the tooltip
    tooltip=":: ${essid}"
    tooltip+="\nIP Address: ${ip_address}"
    tooltip+="\nSecurity: ${security}"
    tooltip+="\nStrength: ${signal} / 100"
fi


# Determine Wi-Fi icon based on signal strength
if [ "$signal" -ge 80 ]; then
  icon="󰤨" # Strong signal
elif [ "$signal" -ge 60 ]; then
  icon="󰤥" # Good signal
elif [ "$signal" -ge 40 ]; then
  icon="󰤢" # Weak signal
elif [ "$signal" -ge 20 ]; then
  icon="󰤟" # Very weak signal
else
  icon="󰤯" # No signal
fi

# Module and tooltip
echo "{\"text\": \"${icon}\", \"tooltip\": \"${tooltip}\"}"
