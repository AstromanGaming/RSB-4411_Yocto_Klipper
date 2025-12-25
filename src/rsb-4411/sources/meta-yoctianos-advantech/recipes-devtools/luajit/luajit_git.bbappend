LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=d421a5e2a24207f5e260537399a9a38b"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    git://luajit.org/git/luajit-2.0.git;protocol=http;branch=v2.1 \
    file://buildvm.h.patch;sha256=0b0845fac335df71e2c055032f0a3239468f01bbd57a5f503df875443935a4f2 \
"

PV = "git${SRCPV}"
SRCREV = "${AUTOREV}"
