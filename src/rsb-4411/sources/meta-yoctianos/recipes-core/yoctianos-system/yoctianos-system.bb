PN = "yoctianos-system"
PV = "DEV"
PR = "r1"

SUMMARY = "YoctianOS files system package"
LICENSE = "MIT"

SRC_URI = "file://os-release \
           file://hostname \
           file://issue \
           file://hosts \
           file://motd \
           file://LICENSE"

S = "${WORKDIR}"

LIC_FILES_CHKSUM = "file://LICENSE;md5=c9c87ca016344f2a98c6b0802912f8ee"

do_install() {
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/os-release ${D}${sysconfdir}/os-release
    install -m 0644 ${WORKDIR}/hostname ${D}${sysconfdir}/hostname
    install -m 0644 ${WORKDIR}/issue ${D}${sysconfdir}/issue
    install -m 0644 ${WORKDIR}/hosts ${D}${sysconfdir}/hosts
    install -m 0644 ${WORKDIR}/motd ${D}${sysconfdir}/motd
}

FILES:${PN} += " \
    ${sysconfdir}/os-release \
    ${sysconfdir}/hostname \
    ${sysconfdir}/issue \
    ${sysconfdir}/hosts \
    ${sysconfdir}/motd \
"
