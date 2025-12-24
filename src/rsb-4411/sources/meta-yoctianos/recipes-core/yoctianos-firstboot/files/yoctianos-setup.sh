#!/bin/sh
set -e

YOCTIANOS_FILE="/etc/.yoctianos"

# Ensure script is run as root user
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root. Aborting."
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
    exit 0
fi
