SRC_URI = "git://github.com/external-mirrors/${BPN}.git;branch=0.18;protocol=https"
SRCREV = "cda69b696d65a53d5d5e75dfed059a3803e0d700"
PV = "0.18.2"
S = "${WORKDIR}/git"

DEPENDS:remove = "eudev"
DEPENDS:append = " systemd"

PACKAGECONFIG:remove = "libudev"
PACKAGECONFIG:append = " libudev"

LIC_FILES_CHKSUM = "file://LICENSE;md5=89e064f90bcb87796ca335cbd2ce4179"

SOLIBS = ".so"
FILES_SOLIBSDEV = ""

FILES_${PN} += "${libdir}/libwlroots-0.18.so"
FILES_${PN}-dev += "${libdir}/libwlroots.so"

