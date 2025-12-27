#!/bin/bash

if [ "$(id -u)" -eq 0 ]; then
    echo "ERROR: Do not run this script as root."
    exit 1
fi

if ! command -v lsb_release >/dev/null 2>&1; then
    echo "ERROR: lsb_release command not found. Install 'lsb-release'."
    exit 1
fi

UBU_VERSION=$(lsb_release -rs)

if [ "$UBU_VERSION" != "22.04" ]; then
    echo "ERROR: This script must be run on Ubuntu 22.04.X LTS."
    echo "Detected version: $UBU_VERSION"
    exit 1
fi

echo "Ubuntu 22.04.X LTS detected."

# Update and install packages
DEV_FILE="$HOME/.yoctianos-dev"

if [ ! -f "$DEV_FILE" ]; then
    echo "0" > "$DEV_FILE"
fi

YOCTIANOS_DEV_NUM="$(cat "$DEV_FILE")"

if [ "$YOCTIANOS_DEV_NUM" != "1" ]; then
    sudo apt update
    sudo apt install -y gcc-multilib g++-multilib libc6-dev-i386

    echo "1" > "$DEV_FILE"
fi

# Set working directory to RSB-4411
cd ~/YoctianOS-Distro/script/rsb-4411 || {
  echo "Could not enter RSB-4411 directory."
  exit 1
}

# Collect all .sh files from default and User/, excluding local_* and bblayers_*
echo "Available launchable scripts:"
find . -type f -name "*.sh" \
  ! -name "local_*.sh" \
  ! -name "bblayers_*.sh" \
  ! -name "redirector_*.sh" \
  ! -name "update_*.sh" \
  ! -name "memory.sh" \
  -exec basename {} \;

# Prompt user to choose one
read -p "Enter the name of the script to launch: " SCRIPT_NAME

# Search for the selected script in both locations
SCRIPT_PATH=$(find . -type f -name "$SCRIPT_NAME" | head -n 1)

# Validate and launch
if [ -f "$SCRIPT_PATH" ]; then
  chmod +x "$SCRIPT_PATH"
  echo "Launching $SCRIPT_NAME..."
  screen -dmS yoctianos bash "$SCRIPT_PATH"
  screen -r yoctianos
else
  echo "Script '$SCRIPT_NAME' not found."
  exit 1
fi
