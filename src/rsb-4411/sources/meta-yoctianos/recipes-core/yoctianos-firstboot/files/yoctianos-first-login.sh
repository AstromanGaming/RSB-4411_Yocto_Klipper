#!/bin/sh

case "$-" in
    *i*) ;;
    *) exit 0 ;;
esac

cp -n "/etc/.yoctianos.template" \
      "/etc/.yoctianos"

if [ "$(whoami)" = "root" ]; then
        if [ -f /etc/.yoctianos ] && grep -q 'install="false"' /etc/.yoctianos; then
                sh /home/root/yoctianos-setup.sh
        fi
fi
