LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=d421a5e2a24207f5e260537399a9a38b"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    git://luajit.org/git/luajit-2.0.git;protocol=http;branch=v2.1 \
    file://buildvm.h.patch;sha256=3071f393c454034894bd7fba86bcb06b354ea3a64936634fb63135c57b3fa282 \
"

PV = "git${SRCPV}"
SRCREV = "${AUTOREV}"
