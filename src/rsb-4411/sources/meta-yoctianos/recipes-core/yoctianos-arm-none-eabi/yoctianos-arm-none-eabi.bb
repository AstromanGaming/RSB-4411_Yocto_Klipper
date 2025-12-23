DESCRIPTION = "ARM bare-metal toolchain (gcc, binutils, newlib) for YoctianOS ARM hosts"
PN = "yoctianos-arm-none-eabi"
PV = "DEV"
PR = "r4"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=c9c87ca016344f2a98c6b0802912f8ee"

SRC_URI = " \
    ;name=git \
    file://LICENSE \
"

SRC_URI[git.sha256sum] = ""

S = "${WORKDIR}"

do_install() {
    install -d ${D}/opt/yoctianos-arm-none-eabi

    # Copy extracted content
    if [ -d "${S}/yoctianos-arm-none-eabi" ]; then
        cp -a ${S}/yoctianos-arm-none-eabi/* ${D}/opt/yoctianos-arm-none-eabi/
    else
        echo "ERROR: No extracted yoctianos-arm-none-eabi/ directory found in WORKDIR"
        exit 1
    fi

    # Fix ownership to avoid host contamination
    chown -R root:root ${D}/opt/yoctianos-arm-none-eabi
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

# This is a prebuilt external toolchain, not a target package
INHIBIT_DEFAULT_DEPS = "1"
RDEPENDS:${PN} = ""
RRECOMMENDS:${PN} = ""

# Disable QA checks that do not apply to external toolchains
INSANE_SKIP:${PN} += "already-stripped staticdev dev-so file-rdeps ldflags"
