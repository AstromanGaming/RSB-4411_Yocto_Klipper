#!/bin/bash

cd ~/YoctianOS-Distro/src/rsb-4411 && MACHINE=imx6qrsb4411a1 UBOOT_CONFIG=1G DISTRO=fsl-imx-x11 source imx-setup-release.sh -b build_default && bash ~/YoctianOS-Distro/script/rsb-4411/local_default.sh && bash ~/YoctianOS-Distro/script/rsb-4411/bblayers_default.sh && bash ~/YoctianOS-Distro/script/rsb-4411/redirector_default.sh && bash ~/YoctianOS-Distro/script/rsb-4411/update_default.sh && bash ~/YoctianOS-Distro/script/rsb-4411/memory.sh && exec bash
