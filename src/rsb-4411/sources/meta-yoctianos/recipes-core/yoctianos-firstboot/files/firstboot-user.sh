#!/bin/sh
set -e

echo
echo "=== YoctianOS Setup ==="

# Find an existing non-system user (UID >= 1000) if any; explicitly exclude root and nobody
find_existing_user() {
    awk -F: '($3 >= 1000) && ($1 != "nobody") && ($1 != "root") { print $1; exit }' /etc/passwd 2>/dev/null || true
}

# Grant sudo: ensure user can use sudo (defensive, safe)
grant_sudo_for_user() {
    u="$1"
    if [ -z "$u" ]; then
        echo "No user specified for sudo grant"
        return 1
    fi

    # Warn if sudo is missing
    if ! command -v sudo >/dev/null 2>&1; then
        echo "Warning: 'sudo' not found. Install sudo for interactive sudo usage."
    fi

    # If group 'sudo' exists, add user to it (ignore errors)
    if getent group sudo >/dev/null 2>&1; then
        echo "Adding $u to group 'sudo'..."
        usermod -a -G sudo "$u" >/dev/null 2>&1 || true
    fi

    # Create a user-specific sudoers file atomically and require password
    TMP_SUDOERS="$(mktemp /tmp/yoctian_sudoers.XXXXXX)" || return 1
    SUDOERS_DEST="/etc/sudoers.d/99-${u}"

    # Require password (no NOPASSWD)
    printf "%s ALL=(ALL) ALL\n" "$u" > "$TMP_SUDOERS"
    chmod 0440 "$TMP_SUDOERS"

    # Validate the sudoers file syntax; only move it into place if valid
    if command -v visudo >/dev/null 2>&1; then
        if visudo -cf "$TMP_SUDOERS" >/dev/null 2>&1; then
            mv "$TMP_SUDOERS" "$SUDOERS_DEST"
            chmod 0440 "$SUDOERS_DEST"
            echo "Sudo configured for user: $u (password required)"
        else
            echo "Error: sudoers file syntax invalid. Not installing $SUDOERS_DEST"
            rm -f "$TMP_SUDOERS"
            return 1
        fi
    else
        # If visudo not available, be conservative: do not install unvalidated file
        echo "Warning: visudo not available to validate sudoers file. Not installing $SUDOERS_DEST"
        rm -f "$TMP_SUDOERS"
        return 1
    fi

    echo "Note: the user may need to re-login for group membership to take effect."
    return 0
}

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

# Check for existing user (explicitly ignore root)
EXISTING="$(find_existing_user)"
if [ "$EXISTING" = "root" ]; then
    EXISTING=""
fi

if [ -n "$EXISTING" ]; then
    printf "An existing non-system user was found on the system: %s\n" "$EXISTING"
    printf "Use this user (u) or create a new one (n)? [u/n]: "
    read -r CHOICE
    CHOICE="$(echo "$CHOICE" | tr '[:upper:]' '[:lower:]')"
    if [ "$CHOICE" = "u" ] || [ -z "$CHOICE" ]; then
        USER="$EXISTING"
        echo "Using existing user: $USER"
        printf "Change the password for '%s'? [y/N]: " "$USER"
        read -r CHANGE_PASS
        if echo "$CHANGE_PASS" | grep -iq '^y'; then
            while true; do
                if command -v stty >/dev/null 2>&1; then stty -echo; fi
                printf "New password: "
                read -r PASS
                echo
                printf "Confirm: "
                read -r PASS2
                echo
                if command -v stty >/dev/null 2>&1; then stty echo; fi
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
else
    USER=""
fi

# If no existing user chosen, prompt to create one
if [ -z "${USER:-}" ]; then
    while true; do
        printf "Username: "
        read -r USER
        # disallow "root" as a username here
        if [ "$USER" = "root" ]; then
            echo "The username 'root' is not allowed. Please choose another username."
            USER=""
            continue
        fi
        if [ -n "$USER" ]; then break; fi
    done

    # Password prompt (twice)
    while true; do
        if command -v stty >/dev/null 2>&1; then stty -echo; fi
        printf "Password: "
        read -r PASS
        echo
        printf "Confirm password: "
        read -r PASS2
        echo
        if command -v stty >/dev/null 2>&1; then stty echo; fi
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

# Grant sudo to the created/selected user (will require password)
grant_sudo_for_user "$USER" || echo "Warning: failed to fully configure sudo for $USER"

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
TMP_LIST="$(mktemp /tmp/yoctian_repolist.XXXXXX)" || TMP_LIST=""
ADDED=0

# Ensure TMP_LIST is removed on exit if it exists
_cleanup_tmp() {
    [ -n "$TMP_LIST" ] && [ -f "$TMP_LIST" ] && rm -f "$TMP_LIST"
}
trap _cleanup_tmp EXIT HUP INT TERM

echo
printf "Adding APT repositories is recommended. Add repos now? [Y/n]: "
read -r ADDREPOS
ADDREPOS="$(_trim "$ADDREPOS")"
if [ -z "$ADDREPOS" ] || echo "$ADDREPOS" | grep -iq '^y'; then
    echo
    echo "Enter repo URLs. You can add local LAN repos (HTTP or file) and public web repos (HTTP/HTTPS)."
    echo "One URL per prompt; comma-separated URLs allowed on a single line. Press Enter on an empty line to finish."
    LOCAL_TRUST_SET=0
    LOCAL_TRUST="yes"

    while true; do
        printf "Repo URL (leave empty to finish): "
        read -r INPUT
        INPUT="$(_trim "$INPUT")"
        [ -z "$INPUT" ] && break

        if [ "$LOCAL_TRUST_SET" -eq 0 ]; then
            printf "Mark local LAN/file repos as trusted (skip GPG verification)? [Y/n]: "
            read -r ans
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

    if [ "$ADDED" -eq 1 ] && [ -n "$TMP_LIST" ]; then
        mkdir -p "$(dirname "$YOCTIAN_LIST")"
        if [ -f "$YOCTIAN_LIST" ]; then
            awk '!seen[$0]++' "$YOCTIAN_LIST" "$TMP_LIST" > "${TMP_LIST}.uniq" || true
            mv "${TMP_LIST}.uniq" "$YOCTIAN_LIST"
        else
            mv "$TMP_LIST" "$YOCTIAN_LIST"
            TMP_LIST=""
        fi
        chmod 0644 "$YOCTIAN_LIST"
        echo "Added repos to $YOCTIAN_LIST"

        if command -v apt-get >/dev/null 2>&1; then
            apt-get update || true
        fi
    else
        [ -n "$TMP_LIST" ] && rm -f "$TMP_LIST"
        echo "No repos added."
    fi
else
    [ -n "$TMP_LIST" ] && rm -f "$TMP_LIST"
    echo "Skipping APT repo configuration (recommended step skipped)."
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

# Disable this service so it won't run again
if command -v systemctl >/dev/null 2>&1; then
    systemctl disable firstboot-user.service || true
fi

echo "Setup complete! User '${USER}' created or selected."
