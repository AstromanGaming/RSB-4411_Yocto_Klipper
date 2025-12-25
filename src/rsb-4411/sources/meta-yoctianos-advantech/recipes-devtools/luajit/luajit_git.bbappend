LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=d421a5e2a24207f5e260537399a9a38b"

SRC_URI = "git://luajit.org/git/luajit-2.0.git;protocol=http;branch=v2.1"

PV = "git${SRCPV}"
SRCREV = "${AUTOREV}"

# Ensure host build uses native sysroot headers and correct host compiler
HOST_CC = "${BUILD_CC}"
HOST_LDFLAGS = "${BUILD_LDFLAGS}"

# Inject explicit HOST_CFLAGS into the make invocation (use native includes)
EXTRA_OEMAKE:append = " HOST_CFLAGS='${BUILD_CFLAGS} -I${STAGING_INCDIR_NATIVE} -I${STAGING_INCDIR_NATIVE}/gnu' HOST_LDFLAGS='${HOST_LDFLAGS}'"

# Avoid LTO issues
TARGET_CFLAGS:remove = "-flto"
HOST_CFLAGS:remove = "-flto"

# Ensure the environment is exported for the make invocation (robust fallback)
do_compile:prepend() {
    export HOST_CC="${HOST_CC}"
    export HOST_CFLAGS="${BUILD_CFLAGS} -I${STAGING_INCDIR_NATIVE} -I${STAGING_INCDIR_NATIVE}/gnu"
    export HOST_LDFLAGS="${HOST_LDFLAGS}"
    bbnote "HOST_CC=${HOST_CC}"
    bbnote "HOST_CFLAGS=${HOST_CFLAGS}"
}
