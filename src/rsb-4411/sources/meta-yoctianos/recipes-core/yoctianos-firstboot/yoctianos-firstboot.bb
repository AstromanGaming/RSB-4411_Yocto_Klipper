PN = "yoctianos-firstboot"
PV = "0.01"
PR = "r2"

SUMMARY = "YoctianOS DEV preparation (first boot) setup and configuration setup package"
LICENSE = "MIT"

SRC_URI = "file://yoctianos-setup.sh \
           file://global-user.sh \
           file://global-time.sh \
           file://global-misc.sh \
           file://firstboot-apt.sh \
           file://config-apt.sh \
           file://yoctianos-first-login.sh \
           file://LICENSE"

S = "${WORKDIR}"

LIC_FILES_CHKSUM = "file://LICENSE;md5=c9c87ca016344f2a98c6b0802912f8ee"

do_install() {
    # install normal scripts
    install -d ${D}/usr/local/sbin/yoctianos
    install -m 0755 ${WORKDIR}/global-user.sh ${D}/usr/local/sbin/yoctianos/global-user.sh
    install -m 0755 ${WORKDIR}/global-time.sh ${D}/usr/local/sbin/yoctianos/global-time.sh
    install -m 0755 ${WORKDIR}/global-misc.sh ${D}/usr/local/sbin/yoctianos/global-misc.sh
    install -m 0755 ${WORKDIR}/firstboot-apt.sh ${D}/usr/local/sbin/yoctianos/firstboot-apt.sh
    install -m 0755 ${WORKDIR}/config-apt.sh ${D}/usr/local/sbin/yoctianos/config-apt.sh

    # install profile.d unit
    install -d ${D}${sysconfdir}/profile.d
    install -m 0755 ${WORKDIR}/yoctianos-first-login.sh ${D}${sysconfdir}/profile.d/yoctianos-first-login.sh

    # install root user script into /root
    install -d ${D}/root
    install -m 0755 ${WORKDIR}/yoctianos-setup.sh ${D}/root/yoctianos-setup.sh
}

FILES:${PN} += "/root/yoctianos-setup.sh \
        /usr/local/sbin/yoctianos/global-user.sh \
        /usr/local/sbin/yoctianos/global-time.sh \
        /usr/local/sbin/yoctianos/global-misc.sh \
        /usr/local/sbin/yoctianos/firstboot-apt.sh \
        /usr/local/sbin/yoctianos/config-apt.sh \
        ${sysconfdir}/profile.d/yoctianos-first-login.sh"

# Enable sshd at image creation if the sshd unit exists in the rootfs
do_install:append() {
    install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
    if [ -f ${D}/lib/systemd/system/sshd.service ]; then
        ln -sf /lib/systemd/system/sshd.service ${D}${sysconfdir}/systemd/system/multi-user.target.wants/sshd.service || true
    elif [ -f ${D}/lib/systemd/system/ssh.service ]; then
        ln -sf /lib/systemd/system/ssh.service ${D}${sysconfdir}/systemd/system/multi-user.target.wants/ssh.service || true
    fi
}
