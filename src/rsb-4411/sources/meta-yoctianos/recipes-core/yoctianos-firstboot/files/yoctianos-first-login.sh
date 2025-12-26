#!/bin/sh

# Run only for root user
[ "$(id -u)" -ne 0 ] && exit 0

# Run only in an interactive shell
case "$-" in
    *i*) ;;
    *) exit 0 ;;
esac

# Skip if /etc/.yoctianos contains install="true"
if [ -f /etc/.yoctianos ] && grep -q 'install="true"' /etc/.yoctianos; then
    exit 0
else
    sh /home/root/yoctianos-setup.sh
fi
