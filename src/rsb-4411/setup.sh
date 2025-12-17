#!/bin/bash

set -e  # Stop the script if any command fails

# Ask the user for their GitHub name and email
read -p "Enter your GitHub name: " GIT_NAME
read -p "Enter your GitHub email: " GIT_EMAIL

# Check if either value is empty
if [[ -z "$GIT_NAME" || -z "$GIT_EMAIL" ]]; then
  echo "Error: GitHub name and email must not be empty."
  exit 1
fi

# Update packages
sudo apt update
sudo apt install -y git curl

# Configure Git with the provided information
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# Create ~/bin if it doesn't exist
mkdir -p ~/bin

# Download the repo tool
curl -o ~/bin/repo http://commondatastorage.googleapis.com/git-repo-downloads/repo
chmod a+x ~/bin/repo

# Add ~/bin to PATH for this session
export PATH="${PATH}:~/bin"

# Initialize the repo with the specified manifest
repo init -u https://github.com/ADVANTECH-Corp/adv-arm-yocto-bsp.git \
          -b imx-linux-mickledore \
          -m imx6LBVD0029.xml

# Sync the sources
repo sync
