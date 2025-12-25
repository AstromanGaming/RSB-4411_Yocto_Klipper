LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=d421a5e2a24207f5e260537399a9a38b"

SRC_URI = "git://luajit.org/git/luajit-2.0.git;protocol=http;branch=v2.1"

PV = "git${SRCPV}"
SRCREV = "${AUTOREV}"

# Ensure host build uses sysroot headers
EXTRA_OEMAKE:append = " HOST_CC='${BUILD_CC}' HOST_CFLAGS='${BUILD_CFLAGS} -I${STAGING_INCDIR_NATIVE} -I${STAGING_INCDIR_NATIVE}/gnu' HOST_LDFLAGS='${BUILD_LDFLAGS}'"

# Avoid LTO issues
TARGET_CFLAGS:remove = "-flto"
HOST_CFLAGS:remove = "-flto"
