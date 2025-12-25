# Use YoctianOS i.MX U-boot
LIC_FILES_CHKSUM = "file://Licenses/gpl-2.0.txt;md5=b234ee4d69f5fce4486a80fdaf4a4263"

UBOOT_SRC = "git://github.com/YoctianOS/uboot-imx.git;protocol=https"
SRCBRANCH = "adv_v2023.04_6.1.22-2.0.0"
SRC_URI = "${UBOOT_SRC};branch=${SRCBRANCH}"
SRCREV = "${AUTOREV}"
LOCALVERSION = "-${SRCBRANCH}"
