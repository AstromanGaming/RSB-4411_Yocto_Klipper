LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=d421a5e2a24207f5e260537399a9a38b"

SRC_URI = " \
    git://luajit.org/git/luajit-2.0.git;protocol=http;branch=v2.1 \
"

PV = "git${SRCPV}"
SRCREV = "${AUTOREV}"

EXTRA_OEMAKE:append = " HOST_CFLAGS='${BUILD_CFLAGS} -I${STAGING_INCDIR} -I${STAGING_INCDIR}/*"

DEPENDS:append = " linux-libc-headers glibc"

do_install () {
    oe_runmake ${EXTRA_OEMAKEINST} install
}
