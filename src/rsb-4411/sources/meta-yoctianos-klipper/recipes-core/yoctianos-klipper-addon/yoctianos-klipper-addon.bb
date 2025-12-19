SUMMARY = "YoctianOS Klipper Addon"
DESCRIPTION = "Install the YoctianOS-Klipper-Addon repository"
HOMEPAGE = "https://github.com/YoctianOS/YoctianOS-Klipper-Addon"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=c9c87ca016344f2a98c6b0802912f8ee"

PV = "git${SRCPV}"
SRC_URI = "git://github.com/YoctianOS/YoctianOS-Klipper-Addon.git;protocol=https;branch=rsb-4411"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

# No configure/compile steps
do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}/opt/YoctianOS-Klipper-Addon
    cp -R ${S}/. ${D}/opt/YoctianOS-Klipper-Addon
    rm -rf ${D}/opt/YoctianOS-Klipper-Addon/.git
}

FILES:${PN} += "/opt"

inherit allarch
