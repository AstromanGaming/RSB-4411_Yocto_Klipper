PN = "yoctianos-firstboot"
PV = "DEV"
PR = "r8"

SUMMARY = "YoctianOS first boot user setup and/or setup assistant package"
LICENSE = "MIT"

SRC_URI = "file://firstboot-user.sh \
           file://firstboot-user.service \
           file://LICENSE"

S = "${WORKDIR}"

LIC_FILES_CHKSUM = "file://LICENSE;md5=c9c87ca016344f2a98c6b0802912f8ee"

do_install() {
    # install script
    install -d ${D}/usr/local/sbin
    install -m 0755 ${WORKDIR}/firstboot-user.sh ${D}/usr/local/sbin/firstboot-user.sh

    # install systemd unit
    install -d ${D}${sysconfdir}/systemd/system
    install -m 0644 ${WORKDIR}/firstboot-user.service ${D}${sysconfdir}/systemd/system/firstboot-user.service
}

FILES:${PN} += "/usr/local/sbin/firstboot-user.sh \
                ${sysconfdir}/systemd/system/firstboot-user.service"

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
