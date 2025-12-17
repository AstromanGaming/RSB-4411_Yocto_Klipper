# Remove the old NXP glamor patch
SRC_URI:remove = "file://0001-glamor-Fix-fbo-pixmap-format-with-GL_BGRA_EXT.patch"

# Add your fixed patch
SRC_URI += "file://0001-glamor-Fix-fbo-pixmap-format-with-GL_BGRA_EXT-for-GL.patch"

# If you’re using imx-gpu-viv, disable GLX to avoid the 'Dependency gl not found' error
PACKAGECONFIG:remove = "glx"
