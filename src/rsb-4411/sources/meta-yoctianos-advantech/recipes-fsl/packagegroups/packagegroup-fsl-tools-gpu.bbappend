# Override RDEPENDS to drop obsolete viv-autohdmi and add modern GPU packages
RDEPENDS:${PN} = "imx-gpu-viv imx-gpu-viv-demos imx-gpu-sdk imx-gpu-viv-tools imx-gpu-apitrace"
