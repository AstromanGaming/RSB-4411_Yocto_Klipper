#!/bin/sh
set -e

echo
echo "=== YoctianOS first boot setup ==="

# Hostname (optional)
printf "Hostname (leave empty to keep 'yoctianos'): "
read NEWHOST
if [ -n "$NEWHOST" ]; then
    echo "$NEWHOST" > /etc/hostname
    # update /etc/hosts: replace 127.0.1.1 line or append
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

# Username prompt
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

# Grant sudo (create sudoers entry if no sudo group)
if getent group sudo >/dev/null 2>&1; then
    usermod -a -G sudo "$USER" || true
else
    echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99-${USER}
    chmod 0440 /etc/sudoers.d/99-${USER}
fi

# Optional: ask for an APT repository URL and add it (leave empty to skip)
printf "APT repo URL (leave empty to skip): "
read APTURL
if [ -n "$APTURL" ]; then
    ARCH=""
    if command -v dpkg >/dev/null 2>&1; then
        ARCH="$(dpkg --print-architecture 2>/dev/null || true)"
    fi
    if [ -n "$ARCH" ]; then
        echo "deb [arch=${ARCH}] ${APTURL} ./" > /etc/apt/sources.list.d/yoctianos.list
    else
        echo "deb ${APTURL} ./" > /etc/apt/sources.list.d/yoctianos.list
    fi
    chmod 0644 /etc/apt/sources.list.d/yoctianos.list

    # Best-effort update (requires network)
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update || true
    fi
fi

# Update /etc/os-release PRETTY_NAME to include hostname if available
if [ -f /etc/os-release ]; then
    HOSTNAME_DISPLAY="${NEWHOST:-$(cat /etc/hostname 2>/dev/null || echo yoctianos)}"
    sed -i "s/^PRETTY_NAME=.*/PRETTY_NAME=\"YoctianOS DEV (${HOSTNAME_DISPLAY})\"/" /etc/os-release || true
fi

# Disable this service so it won't run again
systemctl disable firstboot-user.service || true

echo "First boot setup complete. User '${USER}' created."
