# Remove the obsolete dependency
RDEPENDS:${PN} = "${@oe_filter_out('xserver-xorg-extension-viv-autohdmi', d.getVar('RDEPENDS:${PN}'))}"

# Add modern GPU packages instead
RDEPENDS:${PN} += "imx-gpu-viv imx-gpu-viv-demos"
