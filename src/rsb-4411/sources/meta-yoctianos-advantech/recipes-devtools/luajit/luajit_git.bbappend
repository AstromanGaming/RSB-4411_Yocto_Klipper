LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=d421a5e2a24207f5e260537399a9a38b"

SRC_URI = " \
    git://luajit.org/git/luajit-2.0.git;protocol=http;branch=v2.1 \
"

PV = "git${SRCPV}"
SRCREV = "${AUTOREV}"

EXTRA_OEMAKE:append = " HOST_CFLAGS='${BUILD_CFLAGS} -I${STAGING_INCDIR} -I${STAGING_INCDIR}/*"

DEPENDS:append = " linux-libc-headers glibc"

do_install:append() {
    if [ -d "${D}${datadir}/lua" ]; then
        rm -rf "${D}${datadir}/lua/5.*" || true
        rmdir --ignore-fail-on-non-empty "${D}${datadir}/lua" 2>/dev/null || true
    fi

    if [ -d "${D}${libdir}/lua" ]; then
        rm -rf "${D}${libdir}/lua/5.*" || true
        rmdir --ignore-fail-on-non-empty "${D}${libdir}/lua" 2>/dev/null || true
    fi
}
