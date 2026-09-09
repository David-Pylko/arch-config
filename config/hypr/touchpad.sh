#!/bin/sh

export STATUS_FILE="/home/david/.config/hypr/touchpad.status"

enable_touchpad() {
  printf "true" > "$STATUS_FILE"
  # hyprctl keyword "device[alpsps/2-alps-dualpoint-touchpad]:enabled" 'true'
  # hyprctl keyword "device[ps/2-logitech-wheel-mouse]:enabled" 'true'
  # hyprctl keyword "device[etps/2-elantech-touchpad]:enabled" 'true'
  # hyprctl keyword "device[ps/2-elantech-touchpad]:enabled" 'true'
  hyprctl keyword "device[tpps/2-elan-trackpoint]:enabled" 'true'
  hyprctl keyword "device[synaptics-tm3471-020]:enabled" 'true'
}

disable_touchpad() {
  printf "false" > "$STATUS_FILE"
  # hyprctl keyword "device[alpsps/2-alps-dualpoint-touchpad]:enabled" 'false'
  # hyprctl keyword "device[ps/2-logitech-wheel-mouse]:enabled" 'false'
  # hyprctl keyword "device[etps/2-elantech-touchpad]:enabled" 'false'
  # hyprctl keyword "device[ps/2-elantech-touchpad]:enabled" 'false'
  hyprctl keyword "device[tpps/2-elan-trackpoint]:enabled" 'false'
  hyprctl keyword "device[synaptics-tm3471-020]:enabled" 'false'
}

if ! [ -f "$STATUS_FILE" ]; then
  enable_touchpad
else
  if [ $(cat "$STATUS_FILE") = "true" ]; then
    disable_touchpad
  elif [ $(cat "$STATUS_FILE") = "false" ]; then
    enable_touchpad
  fi
fi
