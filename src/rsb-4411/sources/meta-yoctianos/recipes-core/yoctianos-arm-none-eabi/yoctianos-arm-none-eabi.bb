DESCRIPTION = "YoctianOS ARM bare-metal toolchain (gcc, binutils, newlib) for ARM hosts"
PN = "yoctianos-arm-none-eabi"
PV = "DEV"
PR = "r1"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=c9c87ca016344f2a98c6b0802912f8ee"

SRC_URI = " \
    file://gcc-arm-none-eabi_14.2.rel1-1_armhf.deb;name=gcc \
    file://binutils-arm-none-eabi_2.44-3+23+b1_armhf.deb;name=binutils \
    file://libnewlib-arm-none-eabi_4.5.0.20241231-1_all.deb;name=newlib \
"

SRC_URI[gcc.sha256sum] = "e1bd53fca05ac6dcf0cb261cc73deb24f58adf971d7ce2fc8edcd40027217e32"
SRC_URI[binutils.sha256sum] = "da213bb8fd20ec453673ccea66697466b0de6785c21529bd02d9b5ec65579cfc"
SRC_URI[newlib.sha256sum] = "b444760d62896f03db89d6db94936929f300b72445763557fa94da32b7732f51"

S = "${WORKDIR}"

do_install() {
    # Create installation directory
    install -d ${D}/opt/yoctianos-arm-none-eabi

    # Simply copy the extracted content into the final destination
    if [ -d "${S}/usr" ]; then
        cp -a ${S}/usr/* ${D}/opt/yoctianos-arm-none-eabi/
    else
        echo "ERROR: No extracted usr/ directory found in WORKDIR"
        exit 1
    fi
}

do_install:append() {
    # Add toolchain to PATH
    install -d ${D}/etc/profile.d
    echo 'export PATH=/opt/yoctianos-arm-none-eabi/bin:$PATH' \
        > ${D}/etc/profile.d/yoctianos-arm-none-eabi.sh
}

FILES:${PN} = " \
    /opt/yoctianos-arm-none-eabi \
    /etc/profile.d/yoctianos-arm-none-eabi.sh \
"

INSANE_SKIP:${PN} = "ldflags"
