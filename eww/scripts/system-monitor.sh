#!/bin/bash

# System Monitor Script for EWW

# Function to get CPU usage
get_cpu_usage() {
    cpu_line=$(head -n1 /proc/stat)
    cpu_times=($cpu_line)

    idle_time=${cpu_times[4]}
    total_time=0
    for time in "${cpu_times[@]:1:4}"; do
        total_time=$((total_time + time))
    done

    sleep 0.1
    cpu_line_new=$(head -n1 /proc/stat)
    cpu_times_new=($cpu_line_new)

    idle_time_new=${cpu_times_new[4]}
    total_time_new=0
    for time in "${cpu_times_new[@]:1:4}"; do
        total_time_new=$((total_time_new + time))
    done

    idle_diff=$((idle_time_new - idle_time))
    total_diff=$((total_time_new - total_time))
    cpu_usage=$((100 * (total_diff - idle_diff) / total_diff))

    echo "$cpu_usage"
}

# Function to get memory usage
get_memory_usage() {
    local mem_info=$(</proc/meminfo)
    local total_mem=$(echo "$mem_info" | awk '/MemTotal/ {print $2}')
    local available_mem=$(echo "$mem_info" | awk '/MemAvailable/ {print $2}')
    local used_mem=$((total_mem - available_mem))
    local mem_usage=$((used_mem * 100 / total_mem))
    local total_gb=$((total_mem / 1024 / 1024))
    local used_gb=$((used_mem / 1024 / 1024))

    echo "$mem_usage|$used_gb|$total_gb"
}

# Function to get network status
get_network_status() {
    local active_interface=""
    local ssid=""

    for interface in /sys/class/net/*/operstate; do
        if [[ -f "$interface" && "$(cat "$interface")" == "up" ]]; then
            active_interface=$(basename $(dirname "$interface"))
            break
        fi
    done

    if [[ -n "$active_interface" ]]; then
        if [[ -d "/sys/class/net/$active_interface/wireless" ]]; then
            if command -v nmcli &> /dev/null; then
                ssid=$(nmcli -t -f active,ssid dev wifi | grep "^yes" | cut -d: -f2 | head -1)
            elif command -v iwconfig &> /dev/null; then
                ssid=$(iwconfig "$active_interface" 2>/dev/null | grep ESSID | cut -d: -f2 | tr -d '"')
            fi
            echo "true|WiFi|$ssid"
        else
            echo "true|Ethernet|$active_interface"
        fi
    else
        echo "false|Disconnected|"
    fi
}

# Function to get battery status
get_battery_status() {
    local battery_path="/sys/class/power_supply/BAT0"

    if [[ -d "$battery_path" ]]; then
        local capacity=$(cat "$battery_path/capacity" 2>/dev/null || echo "0")
        local status=$(cat "$battery_path/status" 2>/dev/null || echo "Unknown")
        echo "$capacity|$status"
    else
        echo "0|Unknown"
    fi
}

# Function to get volume level
get_volume() {
    if command -v pamixer &> /dev/null; then
        local volume=$(pamixer --get-volume 2>/dev/null || echo "0")
        local is_muted=$(pamixer --get-mute 2>/dev/null && echo "true" || echo "false")
        echo "$volume|$is_muted"
    elif command -v amixer &> /dev/null; then
        local volume=$(amixer get Master | grep -o '[0-9]*%' | head -1 | tr -d '%')
        local is_muted=$(amixer get Master | grep -o '\[off\]' && echo "true" || echo "false")
        echo "$volume|$is_muted"
    else
        echo "0|false"
    fi
}

# Function to get brightness level
get_brightness() {
    if command -v brightnessctl &> /dev/null; then
        local brightness=$(brightnessctl g 2>/dev/null || echo "0")
        local max_brightness=$(brightnessctl m 2>/dev/null || echo "100")
        local brightness_percent=$((brightness * 100 / max_brightness))
        echo "$brightness_percent"
    elif [[ -f "/sys/class/backlight/*/brightness" ]]; then
        local brightness_file=$(find /sys/class/backlight -name brightness | head -1)
        local max_brightness_file=$(dirname "$brightness_file")/max_brightness

        if [[ -f "$brightness_file" && -f "$max_brightness_file" ]]; then
            local brightness=$(cat "$brightness_file")
            local max_brightness=$(cat "$max_brightness_file")
            local brightness_percent=$((brightness * 100 / max_brightness))
            echo "$brightness_percent"
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

# Function to get load average
get_load_average() {
    local load_avg=$(cat /proc/loadavg | cut -d' ' -f1)
    echo "$load_avg"
}

# Function to get current time
get_time() {
    date '+%H:%M|%Y-%m-%d'
}

# Function to get disk usage for root filesystem
get_disk_usage() {
    local disk_info=$(df -h /)
    local disk_usage=$(echo "$disk_info" | awk 'NR==2 {print $5}' | tr -d '%')
    local disk_used=$(echo "$disk_info" | awk 'NR==2 {print $3}' | tr -d 'G')
    local disk_total=$(echo "$disk_info" | awk 'NR==2 {print $2}' | tr -d 'G')

    echo "$disk_usage|$disk_used|$disk_total"
}

# Function to generate JSON output for EWW
generate_json() {
    local cpu_usage=$(get_cpu_usage)
    local memory_info=$(get_memory_usage)
    local disk_info=$(get_disk_usage)
    local network_info=$(get_network_status)
    local battery_info=$(get_battery_status)
    local volume_info=$(get_volume)
    local brightness_info=$(get_brightness)
    local load_avg=$(get_load_average)
    local time_info=$(get_time)

    IFS='|' read -r memory_usage memory_used memory_total <<< "$memory_info"
    IFS='|' read -r disk_usage disk_used disk_total <<< "$disk_info"
    IFS='|' read -r network_connected network_type network_ssid <<< "$network_info"
    IFS='|' read -r battery_capacity battery_status <<< "$battery_info"
    IFS='|' read -r volume_level volume_muted <<< "$volume_info"
    IFS='|' read -r current_time current_date <<< "$time_info"

    cat << EOF
{
  "cpu_usage": $cpu_usage,
  "memory_usage": $memory_usage,
  "memory_used": "$memory_used",
  "memory_total": "$memory_total",
  "disk_usage": $disk_usage,
  "disk_used": "$disk_used",
  "disk_total": "$disk_total",
  "network": {
    "connected": $network_connected,
    "type": "$network_type",
    "ssid": "$network_ssid"
  },
  "battery": {
    "capacity": $battery_capacity,
    "status": "$battery_status"
  },
  "volume": $volume_level,
  "volume_muted": $volume_muted,
  "brightness": $brightness_info,
  "load_avg": "$load_avg",
  "time": {
    "time": "$current_time",
    "date": "$current_date"
  }
}
EOF
}

# Function to update EWW variables
update_eww() {
    local json_data
    json_data=$(generate_json)

    local cpu_usage=$(echo "$json_data" | jq -r '.cpu_usage')
    local memory_usage=$(echo "$json_data" | jq -r '.memory_usage')
    local network_connected=$(echo "$json_data" | jq -r '.network.connected')
    local battery_capacity=$(echo "$json_data" | jq -r '.battery.capacity')
    local volume=$(echo "$json_data" | jq -r '.volume')
    local brightness=$(echo "$json_data" | jq -r '.brightness')
    local time=$(echo "$json_data" | jq -r '.time.time')
    local date=$(echo "$json_data" | jq -r '.time.date')
    local disk_usage=$(echo "$json_data" | jq -r '.disk_usage')

    if pgrep -x "eww" > /dev/null; then
        eww update cpu_usage="$cpu_usage"
        eww update memory_usage="$memory_usage"
        eww update disk_usage="$disk_usage"
        eww update network_connected="$network_connected"
        eww update battery_capacity="$battery_capacity"
        eww update volume="$volume"
        eww update brightness="$brightness"
        eww update time='{"'"$time"'": "'"$date"'"}'
        echo "Updated EWW with system monitoring data"
    else
        echo "EWW is not running"
    fi
}

# Main script logic
case "${1:-}" in
    "cpu")
        get_cpu_usage
        ;;
    "memory")
        get_memory_usage
        ;;
    "disk")
        get_disk_usage
        ;;
    "network")
        get_network_status
        ;;
    "battery")
        get_battery_status
        ;;
    "volume")
        get_volume
        ;;
    "brightness")
        get_brightness
        ;;
    "load")
        get_load_average
        ;;
    "time")
        get_time
        ;;
    "json")
        generate_json
        ;;
    "update")
        update_eww
        ;;
    *)
        echo "System Monitor Script for EWW"
        echo "Usage: $0 {cpu|memory|disk|network|battery|volume|brightness|load|time|json|update}"
        echo ""
        echo "Commands:"
        echo "  cpu                  - Get CPU usage percentage"
        echo "  memory               - Get memory usage"
        echo "  disk                 - Get disk usage for root filesystem"
        echo "  network              - Get network status"
        echo "  battery              - Get battery status"
        echo "  volume               - Get volume level"
        echo "  brightness           - Get brightness level"
        echo "  load                 - Get system load average"
        echo "  time                 - Get current time and date"
        echo "  json                 - Output all data as JSON"
        echo "  update               - Update EWW with current system data"
        exit 1
        ;;
esac