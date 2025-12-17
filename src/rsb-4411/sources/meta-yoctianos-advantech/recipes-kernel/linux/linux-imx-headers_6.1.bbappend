KERNEL_SRC = "git://github.com/YoctianOS/linux-imx.git;protocol=https"
SRCBRANCH = "adv_6.1.22_2.0.0"
SRC_URI = "${KERNEL_SRC};branch=${SRCBRANCH}"
SRCREV = "${AUTOREV}"
LOCALVERSION = "-lts-6.1.22"

S = "${WORKDIR}/git"
