# Remove the old NXP glamor patch
SRC_URI:remove = "file://0001-glamor-Fix-fbo-pixmap-format-with-GL_BGRA_EXT.patch"

SRC_URI += "file://fsl/0001-glamor-Fix-fbo-pixmap-format-with-GL_BGRA_EXT-for-GL.patch"

PACKAGECONFIG:remove = "glx"
