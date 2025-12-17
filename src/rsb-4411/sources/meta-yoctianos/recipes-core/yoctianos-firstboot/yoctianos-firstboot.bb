SUMMARY = "YoctianOS first boot user and optional apt repo setup"
LICENSE = "MIT"
SRC_URI = "file://firstboot-user.sh \
           file://firstboot-user.service \
           file://os-release \
           file://hostname \
           file://issue \
           file://hosts \
           file://motd \
           file://LICENSE"

S = "${WORKDIR}"

# Replace the md5 below with the md5sum of files/LICENSE if needed
LIC_FILES_CHKSUM = "file://LICENSE;md5=c9c87ca016344f2a98c6b0802912f8ee"

do_install() {
    # script
    install -d ${D}/usr/local/sbin
    install -m 0755 ${WORKDIR}/firstboot-user.sh ${D}/usr/local/sbin/firstboot-user.sh

    # systemd unit
    install -d ${D}${sysconfdir}/systemd/system
    install -m 0644 ${WORKDIR}/firstboot-user.service ${D}${sysconfdir}/systemd/system/firstboot-user.service

    # identity files
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/os-release ${D}${sysconfdir}/os-release
    install -m 0644 ${WORKDIR}/hostname ${D}${sysconfdir}/hostname
    install -m 0644 ${WORKDIR}/issue ${D}${sysconfdir}/issue
    install -m 0644 ${WORKDIR}/hosts ${D}${sysconfdir}/hosts
    install -m 0644 ${WORKDIR}/motd ${D}${sysconfdir}/motd
}

FILES:${PN} += "/usr/local/sbin/firstboot-user.sh \
                ${sysconfdir}/systemd/system/firstboot-user.service \
                ${sysconfdir}/os-release \
                ${sysconfdir}/hostname \
                ${sysconfdir}/issue \
                ${sysconfdir}/hosts \
                ${sysconfdir}/motd"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "firstboot-user.service"

# Enable sshd at image creation if the sshd unit exists in the rootfs
do_install:append() {
    install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
    if [ -f ${D}/lib/systemd/system/sshd.service ]; then
        ln -sf /lib/systemd/system/sshd.service ${D}${sysconfdir}/systemd/system/multi-user.target.wants/sshd.service || true
    elif [ -f ${D}/lib/systemd/system/ssh.service ]; then
        ln -sf /lib/systemd/system/ssh.service ${D}${sysconfdir}/systemd/system/multi-user.target.wants/ssh.service || true
    fi
}
