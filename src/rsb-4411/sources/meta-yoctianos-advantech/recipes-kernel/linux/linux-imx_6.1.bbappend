LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

SRC_URI = "${KERNEL_SRC}"
KERNEL_SRC ?= "git://github.com/YoctianOS/linux-imx.git;protocol=https;branch=${SRCBRANCH}"
KBRANCH = "${SRCBRANCH}"
SRCBRANCH = "adv_6.1.22_2.0.0"
LOCALVERSION = "-lts-6.1.22"
SRCREV = "${AUTOREV}"
