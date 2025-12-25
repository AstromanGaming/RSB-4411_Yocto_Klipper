# Force LuaJIT host tools (minilua, buildvm) to use Yocto sysroot headers
export HOST_CC = "${BUILD_CC}"
export HOST_CFLAGS = "${BUILD_CFLAGS} -I${STAGING_INCDIR} -I${STAGING_INCDIR}/asm"
export HOST_LDFLAGS = "${BUILD_LDFLAGS}"

# LuaJIT hates LTO and some hardening flags
TARGET_CFLAGS:remove = "-flto"
HOST_CFLAGS:remove = "-flto"
