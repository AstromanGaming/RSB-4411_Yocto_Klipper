FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://0001-disable-forced-glx.patch"

PACKAGECONFIG:remove:pn-mpv = "gl-x11"
PACKAGECONFIG:append:pn-mpv = " egl gles2 x11"

EXTRA_OECONF:remove:pn-mpv = "--enable-gl-x11"
EXTRA_OECONF:append:pn-mpv = " --disable-gl-x11 --enable-egl --enable-gles2"
