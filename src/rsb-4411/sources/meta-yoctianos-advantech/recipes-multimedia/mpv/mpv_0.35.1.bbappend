# Force-disable GLX backend (not supported on i.MX6)
PACKAGECONFIG:remove:pn-mpv = "gl-x11"

# Enable correct GPU path
PACKAGECONFIG:append:pn-mpv = " egl gles2 x11"

# Override any forced configure flags
EXTRA_OECONF:remove:pn-mpv = "--enable-gl-x11"
EXTRA_OECONF:append:pn-mpv = " --disable-gl-x11 --enable-egl --enable-gles2"
