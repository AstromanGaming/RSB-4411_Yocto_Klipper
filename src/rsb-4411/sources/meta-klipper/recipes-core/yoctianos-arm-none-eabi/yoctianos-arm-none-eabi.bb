SUMMARY = "Klipper Standalone ARM bare-metal toolchain (gcc, binutils, newlib) for YoctianOS DEV ARM hosts"
DESCRIPTION = "Klipper Standalone ARM bare-metal toolchain (gcc, binutils, newlib) for YoctianOS DEV ARM hosts"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://share/licenses/yoctianos/LICENSE;md5=c9c87ca016344f2a98c6b0802912f8ee"

PN = "yoctianos-arm-none-eabi"
PV = "0.02"
PR = "r0"

SRC_URI = " \
    https://github.com/YoctianOS/yoctianos-arm-none-eabi/releases/download/0.02/yoctianos-arm-none-eabi.tar.xz \
"
SRC_URI[sha256sum] = "7c70ceeae642adcf178b7defbf06928b8c48e3a88cc44bf340ec0337c7317b81"

# If the tarball extracts into a top-level directory named yoctianos-arm-none-eabi
S = "${WORKDIR}/yoctianos-arm-none-eabi"

# Prebuilt external toolchain settings
INHIBIT_DEFAULT_DEPS = "1"
RDEPENDS_${PN} = ""
RRECOMMENDS_${PN} = ""

# Skip QA checks that do not apply to external toolchains
INSANE_SKIP:${PN} += "already-stripped staticdev dev-so file-rdeps ldflags"

do_install() {
    # ensure destination exists
    install -d -m 0777 ${D}/opt/yoctianos-arm-none-eabi

    # Copy extracted content into the package destination
    if [ -d "${S}" ]; then
        cp -a ${S}/* ${D}/opt/yoctianos-arm-none-eabi
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

    # Normalize ownership and permissions to avoid host-owned files in package
    chown -R 0:0 ${D}/opt/yoctianos-arm-none-eabi || true
    find ${D}/opt/yoctianos-arm-none-eabi -type d -exec chmod 0777 {} \; || true
    find ${D}/opt/yoctianos-arm-none-eabi -type f -exec chmod 0777 {} \; || true
}

# Do NOT append ${PN} to PACKAGES (avoids duplicate-package QA error).
# Explicitly include the toolchain directory and the profile script so files are shipped.
FILES:${PN} = "/opt/yoctianos-arm-none-eabi /opt/yoctianos-arm-none-eabi/* /etc/profile.d/yoctianos-arm-none-eabi.sh"
