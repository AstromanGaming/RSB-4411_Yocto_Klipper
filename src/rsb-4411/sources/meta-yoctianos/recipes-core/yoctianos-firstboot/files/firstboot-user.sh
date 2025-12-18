#!/bin/sh
set -e

echo
echo "=== YoctianOS Setup ==="

# Find an existing non-system user (UID >= 1000) if any
find_existing_user() {
    EXISTING_USER="$(awk -F: '($3 >= 1000) && ($1 != "nobody") { print $1; exit }' /etc/passwd 2>/dev/null || true)"
    echo "$EXISTING_USER"
}

# Hostname (optional)
printf "Hostname (leave empty to keep the existing one): "
read NEWHOST
if [ -n "$NEWHOST" ]; then
    echo "$NEWHOST" > /etc/hostname
    if grep -q '^127\.0\.1\.1' /etc/hosts 2>/dev/null; then
        sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t${NEWHOST}/" /etc/hosts
    else
        echo "127.0.1.1\t${NEWHOST}" >> /etc/hosts
    fi
    if command -v hostnamectl >/dev/null 2>&1; then
        hostnamectl set-hostname "$NEWHOST" || true
    else
        hostname "$NEWHOST" || true
    fi
fi

# Check for existing user
EXISTING="$(find_existing_user)"
if [ -n "$EXISTING" ]; then
    printf "An existing user was found on the system: %s\n" "$EXISTING"
    printf "Use this user (u) or create a new one (n)? [u/n]: "
    read CHOICE
    CHOICE="$(echo "$CHOICE" | tr '[:upper:]' '[:lower:]')"
    if [ "$CHOICE" = "u" ] || [ -z "$CHOICE" ]; then
        USER="$EXISTING"
        echo "Using existing user: $USER"
        printf "Change the password for '%s'? [y/N]: " "$USER"
        read CHANGE_PASS
        if echo "$CHANGE_PASS" | grep -iq '^y'; then
            while true; do
                stty -echo
                printf "New password: "
                read PASS
                echo
                printf "Confirm: "
                read PASS2
                echo
                stty echo
                if [ "$PASS" = "$PASS2" ] && [ -n "$PASS" ]; then
                    echo "${USER}:${PASS}" | chpasswd
                    echo "Password updated for $USER"
                    break
                else
                    echo "Passwords do not match or are empty. Try again."
                fi
            done
        fi
    else
        USER=""
    fi
fi

# If no existing user chosen, prompt to create one
if [ -z "${USER:-}" ]; then
    while true; do
        printf "Username: "
        read USER
        if [ -n "$USER" ]; then break; fi
    done

    # Password prompt (twice)
    while true; do
        stty -echo
        printf "Password: "
        read PASS
        echo
        printf "Confirm password: "
        read PASS2
        echo
        stty echo
        if [ "$PASS" = "$PASS2" ] && [ -n "$PASS" ]; then
            break
        else
            echo "Passwords do not match or are empty. Try again."
        fi
    done

    # Create user and set password
    if ! id "$USER" >/dev/null 2>&1; then
        useradd -m -s /bin/bash "$USER" || exit 1
    fi
    echo "${USER}:${PASS}" | chpasswd
    echo "User '$USER' created."
fi

# Grant sudo (create sudoers entry if no sudo group)
if getent group sudo >/dev/null 2>&1; then
    usermod -a -G sudo "$USER" || true
else
    echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99-${USER}
    chmod 0440 /etc/sudoers.d/99-${USER}
fi

# Helper to trim whitespace
_trim() {
    echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Determine architecture for web repos only (optional)
WEB_ARCH=""
if command -v dpkg >/dev/null 2>&1; then
    WEB_ARCH="$(dpkg --print-architecture 2>/dev/null || true)"
fi

YOCTIAN_LIST="/etc/apt/sources.list.d/yoctianos.list"
TMP_LIST="$(mktemp)"
ADDED=0

echo
printf "Adding APT repositories is recommended. Add repos now? [Y/n]: "
read ADDREPOS
ADDREPOS="$(_trim "$ADDREPOS")"
if [ -z "$ADDREPOS" ] || echo "$ADDREPOS" | grep -iq '^y'; then
    echo
    echo "Enter repo URLs. You can add local LAN repos (HTTP or file) and public web repos (HTTP/HTTPS)."
    echo "One URL per prompt; comma-separated URLs allowed on a single line. Press Enter on an empty line to finish."
    LOCAL_TRUST_SET=0
    LOCAL_TRUST="yes"

    while true; do
        printf "Repo URL (leave empty to finish): "
        read INPUT
        INPUT="$(_trim "$INPUT")"
        [ -z "$INPUT" ] && break

        if [ "$LOCAL_TRUST_SET" -eq 0 ]; then
            printf "Mark local LAN/file repos as trusted (skip GPG verification)? [Y/n]: "
            read ans
            ans="$(_trim "$ans")"
            if [ -z "$ans" ] || echo "$ans" | grep -iq '^y'; then
                LOCAL_TRUST="yes"
            else
                LOCAL_TRUST="no"
            fi
            LOCAL_TRUST_SET=1
        fi

        OLDIFS="$IFS"
        IFS=','
        for u in $INPUT; do
            u="$(_trim "$u")"
            [ -z "$u" ] && continue

            case "$u" in
                http://*|https://*|file://*) url="$u" ;;
                *) url="http://$u" ;;
            esac

            is_local=0
            case "$url" in
                file://*) is_local=1 ;;
                http://*|https://*)
                    host="$(echo "$url" | sed -E 's#^[a-z]+://##' | cut -d/ -f1)"
                    if echo "$host" | grep -Eq '^10\.|^192\.168\.|^172\.(1[6-9]|2[0-9]|3[0-1])\.' || echo "$host" | grep -Eq '\.local$'; then
                        is_local=1
                    fi
                    ;;
            esac

            # Build deb line:
            # - Local repos: do NOT include architecture; optionally mark trusted
            # - Web/public repos: include architecture if available (WEB_ARCH)
            if [ "$is_local" -eq 1 ]; then
                if [ "$LOCAL_TRUST" = "yes" ]; then
                    printf "deb [trusted=yes] %s ./\n" "$url" >> "$TMP_LIST"
                else
                    printf "deb %s ./\n" "$url" >> "$TMP_LIST"
                fi
            else
                if [ -n "$WEB_ARCH" ]; then
                    printf "deb [arch=%s] %s ./\n" "$WEB_ARCH" "$url" >> "$TMP_LIST"
                else
                    printf "deb %s ./\n" "$url" >> "$TMP_LIST"
                fi
            fi

            ADDED=1
        done
        IFS="$OLDIFS"
    done

    if [ "$ADDED" -eq 1 ]; then
        mkdir -p "$(dirname "$YOCTIAN_LIST")"
        if [ -f "$YOCTIAN_LIST" ]; then
            cat "$YOCTIAN_LIST" "$TMP_LIST" | awk '!seen[$0]++' > "${TMP_LIST}.uniq"
            mv "${TMP_LIST}.uniq" "$YOCTIAN_LIST"
        else
            mv "$TMP_LIST" "$YOCTIAN_LIST"
        fi
        chmod 0644 "$YOCTIAN_LIST"
        echo "Added repos to $YOCTIAN_LIST"

        if command -v apt-get >/dev/null 2>&1; then
            apt-get update || true
        fi
    else
        rm -f "$TMP_LIST"
        echo "No repos added."
    fi
else
    echo "Skipping APT repo configuration (recommended step skipped)."
fi

# Update /etc/os-release PRETTY_NAME to include hostname if available
if [ -f /etc/os-release ]; then
    HOSTNAME_DISPLAY="${NEWHOST:-$(cat /etc/hostname 2>/dev/null || echo yoctianos)}"
    sed -i "s/^PRETTY_NAME=.*/PRETTY_NAME=\"YoctianOS DEV (${HOSTNAME_DISPLAY})\"/" /etc/os-release || true
fi

# Disable this service so it won't run again
systemctl disable firstboot-user.service || true

echo "Setup complete! User '${USER}' created or selected."
