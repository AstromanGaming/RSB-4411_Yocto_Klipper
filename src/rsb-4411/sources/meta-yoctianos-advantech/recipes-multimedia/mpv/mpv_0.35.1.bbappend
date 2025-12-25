# i.MX6 Vivante GPU does NOT support desktop OpenGL or GLX
# Remove opengl PACKAGECONFIG so the recipe never triggers GLX logic
PACKAGECONFIG:remove:pn-mpv = "opengl gl-x11 vdpau-gl-x11"

# Enable the correct GPU path: EGL + GLES2 + X11
PACKAGECONFIG:append:pn-mpv = " egl gles2 x11"

# Force-disable GLX in case anything tries to re-add it
EXTRA_OECONF:append:pn-mpv = " --disable-gl-x11 --disable-lua"

# Also remove any GLX flags the recipe may have appended
EXTRA_OECONF:remove:pn-mpv = "--enable-gl-x11"
