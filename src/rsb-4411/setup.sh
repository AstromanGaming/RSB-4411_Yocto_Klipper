#!/bin/bash
set -e  # Stop the script if any command fails

# Ask the user for their Git name and email
read -p "Enter your Git name: " GIT_NAME
read -p "Enter your Git email: " GIT_EMAIL

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
