#!/usr/bin/env bash

# Updated for iwd (iwctl)

# Rofi config
config="$HOME/.config/rofi/wifi-menu.rasi"

option_disabled="󰤥  Enable Wi-Fi"

# Rofi window override
override_ssid="entry { placeholder: \"Enter SSID\"; } listview { lines: 0; padding: 20px 6px; }"
override_password="entry { placeholder: \"Enter password\"; } listview { lines: 0; padding: 20px 6px; }"
override_disabled="mainbox { children: [ textbox-custom, listview ]; } listview { lines: 1; padding: 6px 6px 8px; }"

# Prompt for password
get_password() {
  rofi -dmenu -password -config "${config}" -theme-str "${override_password}" -p " " || pkill -x rofi
}

# Get Wi-Fi station device
get_device() {
  local dev
  dev=$(iwctl station list | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' | awk 'NR>4 && NF>=2 {print $1; exit}')
  if [ -z "$dev" ]; then
    dev=$(iwctl device list | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' | awk 'NR>4 && NF>=3 {print $1; exit}')
  fi
  echo "${dev:-wlan0}"
}

# Get Wi-Fi powered status ("enabled" or "disabled")
get_wifi_status() {
  local dev="$1"
  local state
  state=$(iwctl device "$dev" show | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' | awk '/Powered/ {print $NF}')
  if [ "$state" = "on" ]; then
    echo "enabled"
  else
    echo "disabled"
  fi
}

# Get currently connected SSID (if any)
get_connected_ssid() {
  local dev="$1"
  iwctl station "$dev" show | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' | awk -F 'Connected network' 'NF>1 {
    sub(/^[ \t]+/, "", $2)
    sub(/[ \t]+$/, "", $2)
    print $2
  }'
}

# Check if an SSID is a known network in iwd
is_known_network() {
  local ssid="$1"
  local known
  known=$(iwctl known-networks list | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' | awk '
    /Name.*Security/ { sec_idx = index($0, "Security"); next }
    sec_idx > 0 && NF > 0 && !/^-+/ {
      name = substr($0, 1, sec_idx - 1)
      sub(/^[ \t]+/, "", name)
      sub(/[ \t]+$/, "", name)
      if (name != "") print name
    }
  ')
  grep -Fxq "$ssid" <<< "$known"
}

# Run connection command and verify success
connect_network() {
  local output
  output=$("$@" 2>&1)
  local status=$?
  local clean_output
  clean_output=$(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' <<< "$output")
  if [ $status -eq 0 ] && ! grep -qiE "fail|error|invalid|not found" <<< "$clean_output"; then
    return 0
  else
    return 1
  fi
}

while true; do
  device=$(get_device)

  wifi_list() {
    iwctl station "$device" scan 2>/dev/null
    iwctl station "$device" get-networks | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' | awk '
      /Network name.*Security/ {
        sec_idx = index($0, "Security")
        next
      }
      sec_idx > 0 && NF > 0 && !/^-+/ {
        line_ssid = substr($0, 1, sec_idx - 1)
        sub(/^[ >\t]+/, "", line_ssid)
        sub(/[ \t]+$/, "", line_ssid)

        rest = substr($0, sec_idx)
        split(rest, arr)
        sec = arr[1]

        if (line_ssid != "") {
          if (sec == "open") {
            icon = "󰤨"
          } else {
            icon = "󰤪"
          }
          print icon "  " line_ssid
        }
      }
    ' | awk '!seen[$0]++'
  }

  # Get Wi-Fi status
  wifi_status=$(get_wifi_status "$device")

  case "$wifi_status" in
  *"enabled"*)
    connected_ssid=$(get_connected_ssid "$device")

    if [ -n "$connected_ssid" ]; then
      options=$(
        echo "  Manual Entry"
        echo "󰤭  Disconnect ($connected_ssid)"
        echo "󰤮  Disable Wi-Fi"
      )
    else
      options=$(
        echo "  Manual Entry"
        echo "󰤮  Disable Wi-Fi"
      )
    fi

    networks=$(wifi_list)
    if [ -n "$networks" ]; then
      menu_items="$options"$'\n'"$networks"
    else
      menu_items="$options"
    fi

    selected_option=$(echo "$menu_items" |
      rofi -dmenu -i -selected-row 1 -config "${config}" -p " " || pkill -x rofi)
    ;;
  *"disabled"*)
    selected_option=$(echo "$option_disabled" |
      rofi -dmenu -i -config "${config}" -theme-str "${override_disabled}" || pkill -x rofi)
    ;;
  esac

  # Extract selected SSID (removes icon and following spaces)
  selected_ssid="${selected_option#*  }"

  # Actions based on selected option
  case "$selected_option" in
  "")
    exit
    ;;
  *"Enable Wi-Fi"*)
    notify-send "Scanning for networks..." -i "package-installed-outdated"
    rfkill unblock wifi 2>/dev/null
    iwctl device "$device" set-property Powered on 2>/dev/null
    sleep 1
    iwctl station "$device" scan 2>/dev/null
    sleep 2
    ;;
  *"Disable Wi-Fi"*)
    notify-send "Wi-Fi Disabled" -i "package-broken"
    rfkill block wifi 2>/dev/null
    iwctl device "$device" set-property Powered off 2>/dev/null
    exit
    ;;
  *"Disconnect"*)
    notify-send "Disconnecting from \"$connected_ssid\"..." -i "package-installed-outdated"
    if iwctl station "$device" disconnect; then
      notify-send "Disconnected from \"$connected_ssid\"." -i "package-installed-outdated"
    fi
    exit
    ;;
  *"Manual Entry"*)
    # Prompt for SSID
    manual_ssid=$(rofi -dmenu -config "${config}" -theme-str "${override_ssid}" -p " " || pkill -x rofi)

    # Exit if no option is selected
    if [ -z "$manual_ssid" ]; then
      exit
    fi

    # Prompt for Wi-Fi password
    wifi_password=$(get_password)

    notify-send "Connecting to \"$manual_ssid\"..." -i "package-installed-outdated"
    if [ -z "$wifi_password" ]; then
      # Without password (open network or hidden open network)
      if connect_network iwctl station "$device" connect "$manual_ssid" || \
         connect_network iwctl station "$device" connect-hidden "$manual_ssid"; then
        notify-send "Connected to \"$manual_ssid\"." -i "package-installed-outdated"
        exit
      else
        notify-send "Failed to connect to \"$manual_ssid\"." -i "package-broken"
      fi
    else
      # With password (secured network or hidden secured network)
      if connect_network iwctl --passphrase "$wifi_password" station "$device" connect "$manual_ssid" || \
         connect_network iwctl --passphrase "$wifi_password" station "$device" connect-hidden "$manual_ssid"; then
        notify-send "Connected to \"$manual_ssid\"." -i "package-installed-outdated"
        exit
      else
        notify-send "Failed to connect to \"$manual_ssid\"." -i "package-broken"
      fi
    fi
    ;;
  *)
    # If already connected to this network
    if [ -n "$connected_ssid" ] && [ "$selected_ssid" = "$connected_ssid" ]; then
      notify-send "Already connected to \"$selected_ssid\"." -i "package-installed-outdated"
      exit
    fi

    # Connect to a known network
    if is_known_network "$selected_ssid"; then
      notify-send "Connecting to \"$selected_ssid\"..." -i "package-installed-outdated"
      if connect_network iwctl station "$device" connect "$selected_ssid"; then
        notify-send "Connected to \"$selected_ssid\"." -i "package-installed-outdated"
        exit
      else
        notify-send "Failed to connect to \"$selected_ssid\"." -i "package-broken"
      fi
    else
      # Handle secured network connection (prompts for passphrase)
      if [[ "$selected_option" =~ ^"󰤪" ]]; then
        wifi_password=$(get_password)
        if [ -z "$wifi_password" ]; then
          exit
        fi

        notify-send "Connecting to \"$selected_ssid\"..." -i "package-installed-outdated"
        if connect_network iwctl --passphrase "$wifi_password" station "$device" connect "$selected_ssid"; then
          notify-send "Connected to \"$selected_ssid\"." -i "package-installed-outdated"
          exit
        else
          notify-send "Failed to connect to \"$selected_ssid\"." -i "package-broken"
        fi
      else
        # Handle open network connection
        notify-send "Connecting to \"$selected_ssid\"..." -i "package-installed-outdated"
        if connect_network iwctl station "$device" connect "$selected_ssid"; then
          notify-send "Connected to \"$selected_ssid\"." -i "package-installed-outdated"
          exit
        else
          notify-send "Failed to connect to \"$selected_ssid\"." -i "package-broken"
        fi
      fi
    fi
    ;;
  esac
done
