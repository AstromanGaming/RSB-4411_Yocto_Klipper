LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=d421a5e2a24207f5e260537399a9a38b"

SRC_URI = " \
    git://luajit.org/git/luajit-2.0.git;protocol=http;branch=v2.1 \
    file://fix-errno-include.patch \
"

SRC_URI:append = " file://fix-errno-include.patch;md5=3e6b0b9adcace5054f4342ac7ae98909;sha256=5ab60ee95eed72ac3728e676f6634e5e62ed6ee25dfd18c925736a74781bfa06"

PV = "git${SRCPV}"
SRCREV = "${AUTOREV}"
