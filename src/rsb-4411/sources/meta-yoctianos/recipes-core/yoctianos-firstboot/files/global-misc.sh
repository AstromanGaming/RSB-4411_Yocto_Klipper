#!/bin/sh

# This script must be run as root user.
if [ "$(whoami)" = "root" ]; then
    echo "ERROR: This script must be run as root user. Aborting."
    exit 1
fi

echo
echo "=== YoctianOS Setup: System ==="

# Prompt and apply a root password for SSH access
printf "Do you want to set/change the root password now? [y/N]: "
read -r REPLY
if [ "${REPLY,,}" = "y" ]; then
    # Secure password entry and confirmation
    while :; do
        printf "New root password: "
        read -r -s PASS
        echo
        printf "Confirm password: "
        read -r -s PASS2
        echo
        if [ -z "$PASS" ]; then
            echo "Password cannot be empty. Try again."
            continue
        fi
        if [ "$PASS" != "$PASS2" ]; then
            echo "Passwords do not match. Try again."
            continue
        fi
        break
    done

    # Apply the password in the safest portable way possible
    if command -v chpasswd >/dev/null 2>&1; then
        printf 'root:%s\n' "$PASS" | chpasswd
        echo "Root password updated with chpasswd."
    else
        echo "chpasswd not found. Falling back to interactive passwd."
        passwd root || echo "passwd failed. Please set the password manually."
    fi

    # Clear sensitive variables
    PASS=""
    PASS2=""
    unset PASS PASS2
fi

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
    if grep -q '^PRETTY_NAME=' /etc/os-release 2>/dev/null; then
        sed -i "s/^PRETTY_NAME=.*/PRETTY_NAME=\"YoctianOS DEV (${HOSTNAME_DISPLAY})\"/" /etc/os-release || true
    else
        printf 'PRETTY_NAME="YoctianOS DEV (%s)"\n' "$HOSTNAME_DISPLAY" >> /etc/os-release
    fi
fi

echo "System setup complete!"
