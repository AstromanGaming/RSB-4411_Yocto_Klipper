#!/bin/bash

if [ "$(id -u)" -eq 0 ]; then
    echo "ERROR: Do not run this script as root."
    exit 1
fi

# Prompt for build directory name (no default allowed)
read -p "Enter build sub-directory name [build_X]: " BUILD_DIR

# Check if input is empty
if [ -z "$BUILD_DIR" ]; then
  echo "Build directory name is required. Exiting."
  exit 1
fi

# Define paths
CUSTOM_DIR=~/YoctianOS-Distro/script/rsb-4411/User
OUTPUT_SCRIPT="$CUSTOM_DIR/$BUILD_DIR.sh"
LOCAL_SCRIPT="$CUSTOM_DIR/local_$BUILD_DIR.sh"
BBLAYERS_SCRIPT="$CUSTOM_DIR/bblayers_$BUILD_DIR.sh"
REDIRECTOR_SCRIPT="$CUSTOM_DIR/redirector_$BUILD_DIR.sh"

# Create main setup script
cat << EOF > "$OUTPUT_SCRIPT"
#!/bin/bash

cd ~/YoctianOS-Distro/src/rsb-4411 && MACHINE=imx6qrsb4411a1 UBOOT_CONFIG=1G DISTRO=fsl-imx-x11 source imx-setup-release.sh -b build_$BUILD_DIR && bash ~/YoctianOS-Distro/script/rsb-4411/User/local_$BUILD_DIR.sh && bash ~/YoctianOS-Distro/script/rsb-4411/User/bblayers_$BUILD_DIR.sh && bash ~/YoctianOS-Distro/script/rsb-4411/User/redirector_$BUILD_DIR.sh && exec bash
EOF

# Create local_$BUILD_DIR.sh
cat << EOF > "$LOCAL_SCRIPT"
#!/bin/bash

cp ~/YoctianOS-Distro/script/rsb-4411/User/local_$BUILD_DIR.conf ~/YoctianOS-Distro/src/rsb-4411/build_$BUILD_DIR/conf/local.conf
EOF

# Create bblayers_$BUILD_DIR.sh
cat << EOF > "$BBLAYERS_SCRIPT"
#!/bin/bash

cp ~/YoctianOS-Distro/script/rsb-4411/User/bblayers_$BUILD_DIR.conf ~/YoctianOS-Distro/src/rsb-4411/build_$BUILD_DIR/conf/bblayers.conf
EOF

# Create redirector_$BUILD_DIR.sh
cat << EOF > "$REDIRECTOR_SCRIPT"
#!/bin/bash

cp ~/YoctianOS-Distro/script/rsb-4411/redirector.sh.template ~/YoctianOS-Distro/src/rsb-4411/build_$BUILD_DIR/redirector.sh
EOF

# Create the .conf
cp ~/YoctianOS-Distro/script/rsb-4411/User/local.conf.template ~/YoctianOS-Distro/script/rsb-4411/User/local_$BUILD_DIR.conf
cp ~/YoctianOS-Distro/script/rsb-4411/User/bblayers.conf.template ~/YoctianOS-Distro/script/rsb-4411/User/bblayers_$BUILD_DIR.conf

# Make all scripts executable
chmod +x "$OUTPUT_SCRIPT" "$LOCAL_SCRIPT" "$BBLAYERS_SCRIPT" "$REDIRECTOR_SCRIPT"

echo "Scripts created:"
echo " - $OUTPUT_SCRIPT"
echo " - $LOCAL_SCRIPT"
echo " - $BBLAYERS_SCRIPT"
echo " - $REDIRECTOR_SCRIPT"
