#!/bin/sh
set -e

YOCTIANOS_FILE="/etc/.yoctianos"

sed -i 's/restart="true"/restart="false"/' /etc/.yoctianos

# Ensure script is run as root user
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root user. Aborting."
    exit 1
fi

# --- Helper functions --------------------------------------------------------

run_scripts() {
    pattern="$1"
    for script in $pattern; do
        [ -f "$script" ] || continue
        sh "$script"
    done
}

set_install_flag() {
    if [ -f "$YOCTIANOS_FILE" ]; then
        sed -i 's/install="false"/install="true"/' "$YOCTIANOS_FILE"
    fi
}

get_install_status() {
    if [ ! -f "$YOCTIANOS_FILE" ]; then
        echo "false"
        return
    fi

    case "$(grep -o 'install="[^"]*"' "$YOCTIANOS_FILE" | cut -d'"' -f2)" in
        true)  echo "true" ;;
        false) echo "false" ;;
        *)     echo "false" ;; # default fallback
    esac
}

wait_for_cancel() {
    # $1 = seconds
    seconds="$1"

    echo "Press any key to cancel"

    # Make input non-blocking
    stty -icanon -echo min 0 time 0

    while [ "$seconds" -gt 0 ]; do
        printf "%s\n" "$seconds"
        sleep 1

        # If a key is pressed, cancel
        if read -r -n 1 key; then
            echo "Cancelled."
            # Restore terminal settings
            stty sane
            exit 0
        fi

        seconds=$((seconds - 1))
    done

    # Restore terminal settings
    stty sane
}

reboot() {
    if [ -f /etc/.yoctianos ] && grep -q 'restart="true"' /etc/.yoctianos; then
        echo "Restart recommended"
        wait_for_cancel 10
        echo "Rebooting..."
        sleep 1
        reboot
    fi
}

# --- Main logic --------------------------------------------------------------

INSTALL_STATUS="$(get_install_status)"

if [ "$INSTALL_STATUS" = "false" ]; then
    echo "1. Preparation: System"
    sh "/usr/local/sbin/yoctianos/global-misc.sh"

    echo "2. Preparation: User"
    sh "/usr/local/sbin/yoctianos/global-user.sh"

    echo "3. Preparation: APT"
    sh "/usr/local/sbin/yoctianos/firstboot-apt.sh"

    echo "4. Preparation: UTC"
    sh "/usr/local/sbin/yoctianos/global-time.sh"

    echo "5. Install: System Addon Packages"
    run_scripts "/usr/local/sbin/yoctianos/addon/global-*.sh"
    run_scripts "/usr/local/sbin/yoctianos/addon/firstboot-*.sh"

    set_install_flag

    echo "Done!"
    reboot
    exit 0
else
    echo "1. Configuration: System"
    sh "/usr/local/sbin/yoctianos/global-misc.sh"

    echo "2. Configuration: User"
    sh "/usr/local/sbin/yoctianos/global-user.sh"

    echo "3. Configuration: APT"
    sh "/usr/local/sbin/yoctianos/config-apt.sh"

    echo "4. Configuration: UTC"
    sh "/usr/local/sbin/yoctianos/global-time.sh"

    echo "5. Update: System Addon Packages"
    run_scripts "/usr/local/sbin/yoctianos/addon/global-*.sh"
    run_scripts "/usr/local/sbin/yoctianos/addon/config-*.sh"

    echo "Done!"
    reboot
    exit 0
fi
