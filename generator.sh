#!/bin/bash

# Prompt for build directory name (no default allowed)
read -p "Enter build sub-directory name [build_X]: " BUILD_DIR

# Check if input is empty
if [ -z "$BUILD_DIR" ]; then
  echo "Build directory name is required. Exiting."
  exit 1
fi

# Define paths
CUSTOM_DIR=~/RSB-4411_Yocto_Klipper/script/imx6LBVD0029/Custom
OUTPUT_SCRIPT="$CUSTOM_DIR/$BUILD_DIR.sh"
LOCAL_SCRIPT="$CUSTOM_DIR/local_$BUILD_DIR.sh"
BBLAYERS_SCRIPT="$CUSTOM_DIR/bblayers_$BUILD_DIR.sh"

# Create main setup script
cat << EOF > "$OUTPUT_SCRIPT"
cd ~/RSB-4411_Yocto_Klipper && MACHINE=imx6qrsb4411a1 UBOOT_CONFIG=1G DISTRO=fsl-imx-xwayland source imx-setup-release.sh -b build_$BUILD_DIR && bash ~/RSB-4411_Yocto_Klipper/script/imx6LBVD0029/Custom/local_$BUILD_DIR.sh && bash ~/RSB-4411_Yocto_Klipper/script/imx6LBVD0029/Custom/bblayers_$BUILD_DIR.sh && exec bash
EOF

# Create local_$BUILD_DIR.sh
cat << EOF > "$LOCAL_SCRIPT"
#!/bin/bash

cp ~/RSB-4411_Yocto_Klipper/script/imx6LBVD0029/Custom/local_$BUILD_DIR.conf ~/RSB-4411_Yocto_Klipper/build_$BUILD_DIR/conf/local.conf
EOF

# Create bblayers_$BUILD_DIR.sh
cat << EOF > "$BBLAYERS_SCRIPT"
#!/bin/bash

cp ~/RSB-4411_Yocto_Klipper/script/imx6LBVD0029/Custom/bblayers_$BUILD_DIR.conf ~/RSB-4411_Yocto_Klipper/build_$BUILD_DIR/conf/bblayers.conf
EOF

# Create the .conf
cp ~/RSB-4411_Yocto_Klipper/script/local.conf.template ~/RSB-4411_Yocto_Klipper/script/imx6LBVD0029/Custom/local_$BUILD_DIR.conf
cp ~/RSB-4411_Yocto_Klipper/script/bblayers.conf.template ~/RSB-4411_Yocto_Klipper/script/imx6LBVD0029/Custom/bblayers_$BUILD_DIR.conf

# Make all scripts executable
chmod +x "$OUTPUT_SCRIPT" "$LOCAL_SCRIPT" "$BBLAYERS_SCRIPT"

echo "Scripts created:"
echo " - $OUTPUT_SCRIPT"
echo " - $LOCAL_SCRIPT"
echo " - $BBLAYERS_SCRIPT"
