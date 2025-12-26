DEPENDS += "linux-libc-headers glibc virtual/kernel"
TOOLCHAIN_TARGET_TASK:append = " linux-libc-headers kernel-dev"
IMAGE_INSTALL:append = " kernel-dev"

S = "${WORKDIR}/git"

do_compile() {
    oe_runmake ${EXTRA_OEMAKE}
}

do_install() {
    oe_runmake ${EXTRA_OEMAKEINST} install
}
