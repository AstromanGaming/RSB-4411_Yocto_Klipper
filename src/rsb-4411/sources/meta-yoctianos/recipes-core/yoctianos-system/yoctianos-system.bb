PN = "yoctianos-system"
PV = "DEV"
PR = "r3"

SUMMARY = "YoctianOS files system package"
LICENSE = "MIT"

SRC_URI = "file://os-release \
           file://hostname \
           file://issue \
           file://hosts \
           file://motd \
           file://LICENSE \
           file://profile \
           file://bash.bashrc \
           file://skel/.bash_profile \
           file://skel/.bashrc"

S = "${WORKDIR}"

LIC_FILES_CHKSUM = "file://LICENSE;md5=c9c87ca016344f2a98c6b0802912f8ee"

do_install() {
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/os-release ${D}${sysconfdir}/os-release
    install -m 0644 ${WORKDIR}/hostname ${D}${sysconfdir}/hostname
    install -m 0644 ${WORKDIR}/issue ${D}${sysconfdir}/issue
    install -m 0644 ${WORKDIR}/hosts ${D}${sysconfdir}/hosts
    install -m 0644 ${WORKDIR}/motd ${D}${sysconfdir}/motd

    # profile and bash system rc
    install -m 0644 ${WORKDIR}/profile ${D}${sysconfdir}/profile
    install -m 0644 ${WORKDIR}/bash.bashrc ${D}${sysconfdir}/bash.bashrc

    # skel for new users
    install -d ${D}${sysconfdir}/skel
    install -m 0644 ${WORKDIR}/skel/.bash_profile ${D}${sysconfdir}/skel/.bash_profile
    install -m 0644 ${WORKDIR}/skel/.bashrc ${D}${sysconfdir}/skel/.bashrc
}

FILES:${PN} += " \
    ${sysconfdir}/os-release \
    ${sysconfdir}/hostname \
    ${sysconfdir}/issue \
    ${sysconfdir}/hosts \
    ${sysconfdir}/motd \
    ${sysconfdir}/profile \
    ${sysconfdir}/bash.bashrc \
    ${sysconfdir}/skel/.bash_profile \
    ${sysconfdir}/skel/.bashrc \
"
