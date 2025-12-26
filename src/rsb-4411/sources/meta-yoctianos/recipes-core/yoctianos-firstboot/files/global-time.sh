#!/bin/sh

CONF_TIMESYNCD="/etc/systemd/timesyncd.conf"
DROPIN_DIR="/etc/systemd/timesyncd.conf.d"
DROPIN_FILE="$DROPIN_DIR/ntp.conf"
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

# Must be root user
if [ "$(whoami)" != "root" ]; then
    die "This script must be run as root user."
fi

mkdir -p "$BACKUP_DIR"
mkdir -p "$DROPIN_DIR"

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

# Edit NTP servers by creating/updating a drop-in file (recommended)
edit_ntp_servers() {
    printf "Enter NTP servers (space separated), or empty to cancel: "
    read -r SERVERS
    SERVERS="$(_trim "$SERVERS")"
    [ -z "$SERVERS" ] && { echo "Cancelled."; return; }

    # Backup existing drop-in if present
    if [ -f "$DROPIN_FILE" ]; then
        backup_file "$DROPIN_FILE"
    fi

    # Write drop-in file atomically
    cat > "$TMP/ntp.conf" <<EOF
[Time]
NTP=$SERVERS
EOF

    mv "$TMP/ntp.conf" "$DROPIN_FILE"
    chmod 0644 "$DROPIN_FILE"
    echo "Created/updated drop-in $DROPIN_FILE with NTP=$SERVERS"

    # Restart timesyncd if available
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl list-unit-files | grep -q '^systemd-timesyncd'; then
            systemctl daemon-reload || true
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
        echo "Contents of $CONF_TIMESYNCD (first 200 lines):"
        echo "----------------------------------------"
        sed -n '1,200p' "$CONF_TIMESYNCD" || true
        echo "----------------------------------------"
    fi
    if [ -f "$DROPIN_FILE" ]; then
        echo
        echo "Contents of $DROPIN_FILE:"
        echo "----------------------------------------"
        sed -n '1,200p' "$DROPIN_FILE" || true
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
