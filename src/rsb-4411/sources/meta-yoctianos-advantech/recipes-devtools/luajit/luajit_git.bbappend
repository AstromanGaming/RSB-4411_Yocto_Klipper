LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=d421a5e2a24207f5e260537399a9a38b"

SRC_URI = " \
    git://luajit.org/git/luajit-2.0.git;protocol=http;branch=v2.1 \
"

PV = "git${SRCPV}"
SRCREV = "${AUTOREV}"

do_compile:prepend() {
    export HOST_CFLAGS="${HOST_CFLAGS} -I${STAGING_INCDIR_NATIVE} -I${STAGING_INCDIR_NATIVE}/linux"
    bbnote "Injected HOST_CFLAGS=${HOST_CFLAGS}"
}
