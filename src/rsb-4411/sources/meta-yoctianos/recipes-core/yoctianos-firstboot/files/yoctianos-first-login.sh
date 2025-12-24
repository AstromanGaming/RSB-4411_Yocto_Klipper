#!/bin/sh

# Run only for root user
[ "$(id -u)" -ne 0 ] && exit 0

# Run only in an interactive shell
case "$-" in
    *i*) ;;
    *) exit 0 ;;
esac

# Function: wait for keypress to cancel reboot
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

# Skip if /etc/.yoctianos contains install="true"
if [ -f /etc/.yoctianos ] && grep -q 'install="true"' /etc/.yoctianos; then
    exit 0
else
    sed -i 's/restart="true"/restart="false"/' /etc/.yoctianos
    sh /home/root/yoctianos-setup.sh

    if [ -f /etc/.yoctianos ] && grep -q 'restart="true"' /etc/.yoctianos; then
        echo "Restart recommended"
        wait_for_cancel 10
        echo "Rebooting..."
        sleep 1
        reboot
    fi
fi
