SRC_URI = "git://github.com/cage-kiosk/${BPN}.git;branch=master;protocol=https"
SRCREV = "e128a9f2511644529fa47701a7147d65d9920488"
PV = "0.2.0"
S = "${WORKDIR}/git"

DEPENDS:remove = "wlroots-0.16"
DEPENDS:append = " wlroots"

PACKAGECONFIG[xwayland] = ""
