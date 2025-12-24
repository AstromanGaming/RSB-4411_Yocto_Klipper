#!/bin/sh
set -euo pipefail

# YoctianOS UTC configuration and reconfiguration script
# - Run as root
# - Uses timedatectl for timezone and NTP enable/disable
# - If systemd-timesyncd exists, can update /etc/systemd/timesyncd.conf
# - Backs up edited files
# - Interactive prompts; safe defaults (UTC, enable NTP)

CONF_TIMESYNCD="/etc/systemd/timesyncd.conf"
BACKUP_DIR="/var/backups/yoctianos-time"
TMP="$(mktemp -d /tmp/yoctianos-time.XXXXXX)"

cleanup() {
    rm -rf "$TMP"
}
trap cleanup EXIT HUP INT TERM

die() {
    echo "ERROR: $*" >&2
    cleanup
    exit 1
}

# Must be root
if [ "$(id -u)" -ne 0 ]; then
    die "This script must be run as root."
fi

mkdir -p "$BACKUP_DIR"

# Helper trim
_trim() {
    printf "%s" "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Show current status
echo
echo "=== YoctianOS Setup: UTC ==="
echo
if command -v timedatectl >/dev/null 2>&1; then
    echo "Current timedatectl status:"
    timedatectl status --no-pager || true
else
    echo "timedatectl not found. Script requires systemd timedatectl for full functionality."
fi
echo

# Ask main action
printf "Action  [1=set timezone to UTC  2=choose timezone  3=toggle NTP  4=edit NTP servers  5=set hwclock  6=show status  q=quit] (default 1): "
read -r ACTION
ACTION="$(_trim "$ACTION")"
[ -z "$ACTION" ] && ACTION="1"

# Helper to backup file
backup_file() {
    file="$1"
    if [ -f "$file" ]; then
        ts="$(date +%Y%m%dT%H%M%S)"
        cp -- "$file" "$BACKUP_DIR/$(basename "$file").$ts.bak"
        echo "Backup saved to $BACKUP_DIR/$(basename "$file").$ts.bak"
    fi
}

# Set timezone to UTC
set_utc() {
    if command -v timedatectl >/dev/null 2>&1; then
        echo "Setting timezone to UTC..."
        timedatectl set-timezone UTC
        echo "Timezone set to UTC."
    else
        die "timedatectl not available; cannot set timezone."
    fi
}

# Choose timezone interactively
choose_timezone() {
    if ! command -v timedatectl >/dev/null 2>&1; then
        die "timedatectl not available; cannot choose timezone."
    fi
    echo "Available timezones sample (use full name, e.g., Europe/Paris)."
    echo "You can list all with: timedatectl list-timezones"
    printf "Enter timezone (empty to cancel): "
    read -r TZ
    TZ="$(_trim "$TZ")"
    [ -z "$TZ" ] && { echo "Cancelled."; return; }
    if timedatectl list-timezones | grep -Fxq "$TZ"; then
        timedatectl set-timezone "$TZ"
        echo "Timezone set to $TZ."
    else
        echo "Timezone not found. No change made."
    fi
}

# Toggle NTP on/off
toggle_ntp() {
    if ! command -v timedatectl >/dev/null 2>&1; then
        die "timedatectl not available; cannot toggle NTP."
    fi
    CURRENT="$(timedatectl show -p NTPSynchronized --value 2>/dev/null || true)"
    # timedatectl set-ntp accepts true/false
    printf "Enable NTP synchronization? [Y/n] (current: %s): " "$CURRENT"
    read -r ans
    ans="$(_trim "$ans")"
    if [ -z "$ans" ] || echo "$ans" | grep -iq '^y'; then
        timedatectl set-ntp true
        echo "NTP enabled."
    else
        timedatectl set-ntp false
        echo "NTP disabled."
    fi
}

# Edit NTP servers for systemd-timesyncd if present
edit_ntp_servers() {
    if [ ! -f "$CONF_TIMESYNCD" ]; then
        echo "systemd-timesyncd config not found at $CONF_TIMESYNCD."
        printf "Do you want to create it and configure NTP servers? [Y/n]: "
        read -r c
        c="$(_trim "$c")"
        if [ -z "$c" ] || echo "$c" | grep -iq '^y'; then
            touch "$CONF_TIMESYNCD"
        else
            echo "Skipping NTP server configuration."
            return
        fi
    fi

    backup_file "$CONF_TIMESYNCD"

    # Show current NTP line if any
    echo
    echo "Current $CONF_TIMESYNCD content:"
    echo "----------------------------------------"
    sed -n '1,200p' "$CONF_TIMESYNCD" || true
    echo "----------------------------------------"
    echo
    printf "Enter NTP servers (space separated), or empty to cancel: "
    read -r SERVERS
    SERVERS="$(_trim "$SERVERS")"
    [ -z "$SERVERS" ] && { echo "Cancelled."; return; }

    # Write new config preserving other settings
    awk -v n="$SERVERS" '
    BEGIN{in_time=0; wrote=0}
    /^

\[Time\]

/{print; in_time=1; next}
    /^

\[/{ if(in_time && !wrote){ print "NTP=" n; wrote=1 } in_time=0; print; next}
    { if(in_time){
        if($0 ~ /^NTP=/){ if(!wrote){ print "NTP=" n; wrote=1 } ; next }
        if($0 ~ /^FallbackNTP=/){ print; next }
        # skip empty lines inside [Time] to avoid duplicates
        if($0 ~ /^[[:space:]]*$/) next
        print
      } else print
    }
    END{ if(!wrote){ if(!in_time) print "[Time]"; print "NTP=" n } }' "$CONF_TIMESYNCD" > "$TMP/timesyncd.conf.new"

    mv "$TMP/timesyncd.conf.new" "$CONF_TIMESYNCD"
    chmod 0644 "$CONF_TIMESYNCD"
    echo "Updated $CONF_TIMESYNCD with NTP=$SERVERS"

    # Restart timesyncd if available
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl list-unit-files | grep -q '^systemd-timesyncd'; then
            systemctl restart systemd-timesyncd || echo "Warning: failed to restart systemd-timesyncd"
            echo "systemd-timesyncd restarted."
        fi
    fi
}

# Set hardware clock to UTC or localtime
set_hwclock() {
    printf "Set hardware clock to UTC? [Y/n]: "
    read -r hw
    hw="$(_trim "$hw")"
    if [ -z "$hw" ] || echo "$hw" | grep -iq '^y'; then
        hwclock --systohc --utc
        echo "Hardware clock set to UTC (systohc --utc)."
    else
        hwclock --systohc --localtime
        echo "Hardware clock set to localtime (systohc --localtime)."
    fi
}

# Show status
show_status() {
    echo
    if command -v timedatectl >/dev/null 2>&1; then
        timedatectl status --no-pager || true
    else
        echo "timedatectl not available."
    fi
    if [ -f "$CONF_TIMESYNCD" ]; then
        echo
        echo "Contents of $CONF_TIMESYNCD:"
        echo "----------------------------------------"
        sed -n '1,200p' "$CONF_TIMESYNCD" || true
        echo "----------------------------------------"
    fi
}

# Execute chosen action
case "$ACTION" in
    1) set_utc; toggle_ntp; set_hwclock ;;
    2) choose_timezone ;;
    3) toggle_ntp ;;
    4) edit_ntp_servers ;;
    5) set_hwclock ;;
    6) show_status ;;
    q|Q) echo "Quit."; exit 0 ;;
    *) echo "Unknown action. Exiting."; exit 1 ;;
esac

echo
echo "UTC setup complete!"
exit 0
