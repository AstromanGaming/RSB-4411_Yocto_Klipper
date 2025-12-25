DESCRIPTION = "Klipper Standalone ARM bare-metal toolchain (gcc, binutils, newlib) for YoctianOS DEV ARM hosts"
PN = "yoctianos-arm-none-eabi"
PV = "0.01"
PR = "r0"

# Add the recipe's files/ directory to the file:// search path
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=c9c87ca016344f2a98c6b0802912f8ee"

SRC_URI = " \
    https://github.com/YoctianOS/yoctianos-arm-none-eabi/releases/download/0.01/yoctianos-arm-none-eabi.tar.xz \
"

SRC_URI[sha256sum] = "25e9c10c6996964a136d54acf63d11bf41d01e5882fb490d9681cc0621b96ba2"

# If the tarball extracts into a top-level directory named yoctianos-arm-none-eabi,
# set S accordingly to simplify do_install paths.
S = "${WORKDIR}/yoctianos-arm-none-eabi"

do_install() {
    install -d -m 0755 ${D}/opt/yoctianos-arm-none-eabi

    # Copy extracted content into the package destination
    if [ -d "${S}" ]; then
        cp -a ${S}/* ${D}/opt/yoctianos-arm-none-eabi/
    else
        bbnote "ERROR: No extracted yoctianos-arm-none-eabi/ directory found in S (${S})"
        exit 1
    fi

    # Create profile.d script to add the toolchain to PATH
    install -d -m 0755 ${D}/etc/profile.d
    cat > ${D}/etc/profile.d/yoctianos-arm-none-eabi.sh << 'EOF'
# Add YoctianOS prebuilt toolchain to PATH
export PATH=/opt/yoctianos-arm-none-eabi/bin:$PATH
EOF
    chmod 0755 ${D}/etc/profile.d/yoctianos-arm-none-eabi.sh
}

FILES_${PN} = " \
    /opt/yoctianos-arm-none-eabi \
    /etc/profile.d/yoctianos-arm-none-eabi.sh \
"

# This is a prebuilt external toolchain, not a target package
INHIBIT_DEFAULT_DEPS = "1"
RDEPENDS_${PN} = ""
RRECOMMENDS_${PN} = ""

# Skip QA checks that do not apply to external toolchains
INSANE_SKIP_${PN} += "already-stripped staticdev dev-so file-rdeps ldflags"
