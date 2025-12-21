DESCRIPTION = "YoctianOS ARM bare-metal toolchain (gcc, binutils, newlib) for ARM hosts"
PN = "yoctianos-arm-none-eabi"
PV = "DEV"
PR = "r1"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=c9c87ca016344f2a98c6b0802912f8ee"

# Official Debian ARMHF packages
SRC_URI = " \
    http://ftp.debian.org/debian/pool/main/g/gcc-arm-none-eabi/gcc-arm-none-eabi_14.2.rel1-1_armhf.deb \
    http://ftp.debian.org/debian/pool/main/b/binutils-arm-none-eabi/binutils-arm-none-eabi_2.44-3+23+b1_armhf.deb \
    http://ftp.debian.org/debian/pool/main/n/newlib/libnewlib-arm-none-eabi_4.5.0.20241231-1_all.deb \
"

# Skip checksums for simplicity
SRC_URI[gcc.sha256sum] = "IGNORE"
SRC_URI[binutils.sha256sum] = "IGNORE"
SRC_URI[newlib.sha256sum] = "IGNORE"

S = "${WORKDIR}"

do_install() {
    # Install directory
    install -d ${D}/opt/yoctianos-arm-none-eabi

    # Extract all .deb files
    for pkg in ${WORKDIR}/*.deb; do
        dpkg-deb -x $pkg ${D}/opt/yoctianos-arm-none-eabi/
    done
}

# Add toolchain to PATH automatically
do_install:append() {
    install -d ${D}/etc/profile.d
    echo 'export PATH=/opt/yoctianos-arm-none-eabi/bin:$PATH' > ${D}/etc/profile.d/yoctianos-arm-none-eabi.sh
}

FILES:${PN} = " \
    /opt/yoctianos-arm-none-eabi \
    /etc/profile.d/yoctianos-arm-none-eabi.sh \
"

INSANE_SKIP:${PN} = "ldflags"
