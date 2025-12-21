#!/bin/bash

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
  ! -name "memory_*.sh" \
  -exec basename {} \;

# Prompt user to choose one
read -p "Enter the name of the script to launch: " SCRIPT_NAME

# Search for the selected script in both locations
SCRIPT_PATH=$(find . -type f -name "$SCRIPT_NAME" | head -n 1)

# Validate and launch
if [ -f "$SCRIPT_PATH" ]; then
  chmod +x "$SCRIPT_PATH"
  echo "Launching $SCRIPT_NAME..."
  bash "$SCRIPT_PATH"
else
  echo "Script '$SCRIPT_NAME' not found."
  exit 1
fi
