#!/bin/bash

set -e

# Function to check and optionally modify global Git identity
ensure_git_identity() {
  local current_name current_email
  current_name=$(git config --global --get user.name || true)
  current_email=$(git config --global --get user.email || true)

  if [[ -n "$current_name" || -n "$current_email" ]]; then
    echo "Current global Git configuration:"
    echo "  user.name:  ${current_name:-<not set>}"
    echo "  user.email: ${current_email:-<not set>}"
    read -p "Do you want to modify these values? [y/N] " modify_choice
    modify_choice=${modify_choice:-N}
    if [[ "$modify_choice" =~ ^[Yy]$ ]]; then
      read -p "Enter new Git name (leave empty to keep '${current_name}'): " new_name
      read -p "Enter new Git email (leave empty to keep '${current_email}'): " new_email

      # Keep existing values if user left input empty
      if [[ -z "$new_name" && -n "$current_name" ]]; then
        new_name="$current_name"
      fi
      if [[ -z "$new_email" && -n "$current_email" ]]; then
        new_email="$current_email"
      fi

      # Require both values to be non-empty
      if [[ -z "$new_name" || -z "$new_email" ]]; then
        echo "Error: Git name and email must not be empty."
        exit 1
      fi

      git config --global user.name "$new_name"
      git config --global user.email "$new_email"
      echo "Global Git configuration updated."
    else
      echo "Keeping existing global Git configuration."
    fi
  else
    # No existing configuration: prompt for values
    read -p "Enter your Git name: " GIT_NAME
    read -p "Enter your Git email: " GIT_EMAIL

    if [[ -z "$GIT_NAME" || -z "$GIT_EMAIL" ]]; then
      echo "Error: Git name and email must be provided."
      exit 1
    fi

    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    echo "Global Git configuration set."
  fi
}

# Update and install packages
sudo apt update
sudo apt install -y git curl

# Check or set Git identity
ensure_git_identity

# Create ~/bin if it doesn't exist
mkdir -p "$HOME/bin"

# Download the repo tool
curl -o "$HOME/bin/repo" http://commondatastorage.googleapis.com/git-repo-downloads/repo
chmod a+x "$HOME/bin/repo"

# Add ~/bin to PATH for this session
export PATH="${PATH}:$HOME/bin"

# Initialize the repo with the specified manifest
repo init -u https://github.com/YoctianOS/adv-arm-yocto-bsp.git \
          -b imx-linux-mickledore \
          -m adv-6.1.22-2.0.0.xml

# Sync the sources
repo sync
