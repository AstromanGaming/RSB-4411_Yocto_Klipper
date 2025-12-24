#!/bin/sh
set -e

# This script must be run as root user.
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root user. Aborting."
    exit 1
fi

echo
echo "=== YoctianOS Setup: System ==="

# Hostname (optional)
printf "Hostname (leave empty to keep the existing one): "
read -r NEWHOST
if [ -n "$NEWHOST" ]; then
    printf '%s\n' "$NEWHOST" > /etc/hostname
    if grep -q '^127\.0\.1\.1' /etc/hosts 2>/dev/null; then
        sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t${NEWHOST}/" /etc/hosts
    else
        printf '127.0.1.1\t%s\n' "$NEWHOST" >> /etc/hosts
    fi
    if command -v hostnamectl >/dev/null 2>&1; then
        hostnamectl set-hostname "$NEWHOST" || true
    else
        hostname "$NEWHOST" || true
    fi
fi

# Update /etc/os-release PRETTY_NAME to include hostname if available
if [ -f /etc/os-release ]; then
    HOSTNAME_DISPLAY="${NEWHOST:-$(cat /etc/hostname 2>/dev/null || echo yoctianos)}"
    # Use a safe sed replace; if PRETTY_NAME not present, append it
    if grep -q '^PRETTY_NAME=' /etc/os-release 2>/dev/null; then
        sed -i "s/^PRETTY_NAME=.*/PRETTY_NAME=\"YoctianOS DEV (${HOSTNAME_DISPLAY})\"/" /etc/os-release || true
    else
        printf 'PRETTY_NAME="YoctianOS DEV (%s)"\n' "$HOSTNAME_DISPLAY" >> /etc/os-release
    fi
fi

echo "System setup complete!"
