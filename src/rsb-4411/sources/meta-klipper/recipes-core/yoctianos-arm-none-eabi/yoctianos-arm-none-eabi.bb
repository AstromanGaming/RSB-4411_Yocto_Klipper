DESCRIPTION = "Klipper Standalone ARM bare-metal toolchain (gcc, binutils, newlib) for YoctianOS DEV ARM hosts"
PN = "yoctianos-arm-none-eabi"
PV = "0.01"
PR = "r0"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://share/licenses/yoctianos/LICENSE;md5=c9c87ca016344f2a98c6b0802912f8ee"
		
SRC_URI = " \
    https://github.com/YoctianOS/yoctianos-arm-none-eabi/releases/download/0.01/yoctianos-arm-none-eabi.tar.xz \
"

SRC_URI[sha256sum] = "6fc0303a1b09300777611ba9567340f4669a4b21c7e8e036fc77e2861cf3f8e7"

# If the tarball extracts into a top-level directory named yoctianos-arm-none-eabi,
S = "${WORKDIR}/yoctianos-arm-none-eabi"

do_install() {
    # ensure destination exists
    install -d -m 0755 ${D}/opt

    # Copy extracted content into the package destination
    if [ -d "${S}" ]; then
        install -d -m 0755 ${D}/opt/yoctianos-arm-none-eabi
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

    # Normalize ownership and permissions to avoid host-owned files in package
    chown -R 0:0 ${D}/opt/yoctianos-arm-none-eabi || true
    find ${D}/opt/yoctianos-arm-none-eabi -type d -exec chmod 0755 {} \; || true
    find ${D}/opt/yoctianos-arm-none-eabi -type f -exec chmod 0644 {} \; || true
    if [ -d "${D}/opt/yoctianos-arm-none-eabi/bin" ]; then
        find ${D}/opt/yoctianos-arm-none-eabi/bin -type f -exec chmod 0755 {} \; || true
    fi
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
INSANE_SKIP:${PN} += "already-stripped staticdev dev-so file-rdeps ldflags"
