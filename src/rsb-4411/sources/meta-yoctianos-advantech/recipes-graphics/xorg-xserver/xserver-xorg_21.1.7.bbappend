# Remove the original NXP glamor patch
SRC_URI:remove = "file://0001-glamor-Fix-fbo-pixmap-format-with-GL_BGRA_EXT.patch"

# Remove Legacy Graphics
PACKAGECONFIG:remove = "glx"
