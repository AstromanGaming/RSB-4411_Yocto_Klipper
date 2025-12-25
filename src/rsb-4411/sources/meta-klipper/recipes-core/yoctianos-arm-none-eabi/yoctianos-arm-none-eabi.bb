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
    file://LICENSE \
"

SRC_URI[sha256sum] = "25e9c10c6996964a136d54acf63d11bf41d01e5882fb490d9681cc0621b96ba2"

# If the tarball extracts into a top-level directory named yoctianos-arm-none-eabi,
# set S accordingly to simplify do_install paths.
S = "${WORKDIR}/yoctianos-arm-none-eabi"

do_install() {
    install -d -m 0755 ${D}/opt/yoctianos-arm-none-eabi

    # Copy extracted content into the package destination, excluding LICENSE
    if [ -d "${S}" ]; then
        rsync -a --delete --exclude='LICENSE' "${S}/" "${D}/opt/yoctianos-arm-none-eabi/"
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

# Normalize ownership and permissions to avoid host-owned files in package
do_install_append() {
    # ensure ownership is root:root for packaging and sstate hashing
    chown -R 0:0 ${D}/opt/yoctianos-arm-none-eabi || true

    # normalize permissions: dirs 755, regular files 644
    find ${D}/opt/yoctianos-arm-none-eabi -type d -exec chmod 0755 {} \; || true
    find ${D}/opt/yoctianos-arm-none-eabi -type f -exec chmod 0644 {} \; || true

    # make executables in bin executable
    if [ -d "${D}/opt/yoctianos-arm-none-eabi/bin" ]; then
        find ${D}/opt/yoctianos-arm-none-eabi/bin -type f -exec chmod 0755 {} \; || true
    fi
}

FILES_${PN} = " \
    /opt/yoctianos-arm-none-eabi \
    /etc/profile.d/yoctianos-arm-none-eabi.sh \
"

# If LICENSE is present inside the extracted tree (S), copy it to license-destdir
# so do_populate_lic can find it during QA. Also prefer recipe files/ LICENSE if present.
do_populate_lic_prepend() {
    mkdir -p ${WORKDIR}/license-destdir/${PN}

    if [ -f "${THISDIR}/files/LICENSE" ]; then
        bbnote "Using LICENSE from recipe files/: ${THISDIR}/files/LICENSE"
        cp -a ${THISDIR}/files/LICENSE ${WORKDIR}/license-destdir/${PN}/LICENSE
        return 0
    fi

    if [ -f "${S}/LICENSE" ]; then
        bbnote "Copying LICENSE from ${S}/LICENSE to license-destdir for QA"
        cp -a ${S}/LICENSE ${WORKDIR}/license-destdir/${PN}/LICENSE
        return 0
    fi

    # fallback: try to find any license-like file under S
    licfile=$(find ${S} -maxdepth 2 -type f -iname 'license*' -print -quit 2>/dev/null)
    if [ -n "${licfile}" ]; then
        bbnote "Found LICENSE at ${licfile}; copying for QA"
        cp -a "${licfile}" ${WORKDIR}/license-destdir/${PN}/LICENSE
        return 0
    fi

    bbwarn "No LICENSE found in recipe files/ or ${S}; do_populate_lic will rely on LIC_FILES_CHKSUM path"
}

# This is a prebuilt external toolchain, not a target package
INHIBIT_DEFAULT_DEPS = "1"
RDEPENDS_${PN} = ""
RRECOMMENDS_${PN} = ""

# Skip QA checks that do not apply to external toolchains
INSANE_SKIP_${PN} += "installed-vs-shipped already-stripped staticdev dev-so file-rdeps ldflags"
