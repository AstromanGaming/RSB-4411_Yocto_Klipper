#!/bin/sh

# This script must be run as root user.
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: This script must be run as root user. Aborting."
    exit 1
fi

echo
echo "=== YoctianOS Setup: User ==="

# Find an existing non-system user (UID >= 1000) if any; explicitly exclude root and nobody
find_existing_user() {
    awk -F: '($3 >= 1000) && ($1 != "nobody") && ($1 != "root") { print $1; exit }' /etc/passwd 2>/dev/null || true
}

# Grant sudo: ensure user can use sudo (defensive, safe)
# This version installs a sudoers file without visudo validation (per request).
grant_sudo_for_user() {
    u="$1"
    if [ -z "$u" ]; then
        echo "No user specified for sudo grant" >&2
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
        usermod -a -G input "$u" >/dev/null 2>&1 || true
        usermod -a -G tty "$u" >/dev/null 2>&1 || true
        usermod -a -G video "$u" >/dev/null 2>&1 || true
    fi

    # Create a user-specific sudoers file atomically and require password
    TMP_SUDOERS="$(mktemp /tmp/yoctian_sudoers.XXXXXX)" || return 1
    SUDOERS_DEST="/etc/sudoers.d/99-${u}"

    # Require password (no NOPASSWD)
    printf "%s ALL=(ALL) ALL\n" "$u" > "$TMP_SUDOERS"
    chmod 0440 "$TMP_SUDOERS"

    # Install the sudoers file (no visudo validation)
    mv "$TMP_SUDOERS" "$SUDOERS_DEST"
    chmod 0440 "$SUDOERS_DEST"
    echo "Sudo configured for user: $u (password required)"

    echo "Note: the user may need to re-login for group membership to take effect."
    return 0
}

# Verify that the user has sudo privileges; if not, try to add them to sudo/wheel and re-check.
# If verification ultimately fails, exit the script (user must have sudo).
verify_user_in_sudo() {
    u="$1"
    if [ -z "$u" ]; then
        echo "verify_user_in_sudo: no user specified" >&2
        return 1
    fi

    user_in_sudo_group() {
        if id -nG "$u" >/dev/null 2>&1; then
            id -nG "$u" | grep -Eq '\b(sudo|wheel)\b' && return 0 || return 1
        fi
        return 1
    }

    user_has_sudoers_file() {
        [ -f "/etc/sudoers.d/99-${u}" ] && return 0 || return 1
    }

    # First check
    if user_in_sudo_group || user_has_sudoers_file; then
        echo "Verification: user '$u' already has sudo privileges."
        return 0
    fi

    echo "User '$u' does not appear to have sudo privileges. Attempting to add to 'sudo' group..."

    # Try to add to sudo or wheel group if present
    if getent group sudo >/dev/null 2>&1; then
        usermod -a -G sudo "$u" >/dev/null 2>&1 || true
        usermod -a -G input "$u" >/dev/null 2>&1 || true
        usermod -a -G tty "$u" >/dev/null 2>&1 || true
        usermod -a -G video "$u" >/dev/null 2>&1 || true
    else
        echo "No 'sudo' group found on this system. Will check for sudoers file."
    fi

    # Short pause to allow group membership to update
    sleep 1

    # Re-check
    if user_in_sudo_group || user_has_sudoers_file; then
        echo "Verification: user '$u' now has sudo privileges."
        return 0
    fi

    # Final check: accept if sudoers file exists
    if user_has_sudoers_file; then
        echo "Verification: sudoers file found for '$u'."
        return 0
    fi

    echo "ERROR: failed to ensure user '$u' has sudo privileges. Aborting." >&2
    exit 1
}

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

# Ensure user has a ~/.bash_profile that sources /etc/profile and ~/.bashrc
USER_HOME="$(getent passwd "$USER" | cut -d: -f6)"
BASH_PROFILE_PATH="${USER_HOME}/.bash_profile"

if [ -n "$USER_HOME" ] && [ -d "$USER_HOME" ]; then
    # Create .bash_profile only if it does not already contain /etc/profile sourcing
    if [ ! -f "$BASH_PROFILE_PATH" ] || ! grep -q '/etc/profile' "$BASH_PROFILE_PATH"; then
        cat > "$BASH_PROFILE_PATH" <<'EOF'
# Source global profile
[ -r /etc/profile ] && . /etc/profile
# Load user's bashrc if present
[ -r ~/.bashrc ] && . ~/.bashrc
EOF
        # Set ownership and permissions
        chown "$USER":"$USER" "$BASH_PROFILE_PATH" 2>/dev/null || true
        chmod 644 "$BASH_PROFILE_PATH" 2>/dev/null || true
        echo "Created $BASH_PROFILE_PATH for user $USER"
    else
        echo "$BASH_PROFILE_PATH already configures /etc/profile"
    fi
else
    echo "Warning: could not determine home directory for $USER; skipping .bash_profile creation"
fi

# Grant sudo to the created/selected user (will require password)
grant_sudo_for_user "$USER" || echo "Warning: failed to fully configure sudo for $USER"

# Verify the user has sudo privileges; exit if verification fails
verify_user_in_sudo "$USER"

echo "User setup complete!"
