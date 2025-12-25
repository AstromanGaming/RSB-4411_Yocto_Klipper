# Major Fix
install_utils() {
    mkdir -p ${IMAGE_ROOTFS}/usr/local/bin
    install -m 0755 ${ADDON_FILES_DIR}/bt_pair.sh ${IMAGE_ROOTFS}/usr/local/bin
    install -m 0755 ${ADDON_FILES_DIR}/bt_send.sh ${IMAGE_ROOTFS}/usr/local/bin
    install -m 0755 ${ADDON_FILES_DIR}/bt_obexd_start.sh ${IMAGE_ROOTFS}/usr/local/bin
    install -m 0755 ${ADDON_FILES_DIR}/bt_obexd_stop.sh ${IMAGE_ROOTFS}/usr/local/bin
    install -m 0755 ${ADDON_FILES_DIR}/mlanutl ${IMAGE_ROOTFS}/usr/local/bin
    mkdir -p ${IMAGE_ROOTFS}/lib/firmware/rtlwifi/rtl8821ae
    install -m 0755 ${ADDON_FILES_DIR}/wifi_ant_isolation.txt ${IMAGE_ROOTFS}/lib/firmware/rtlwifi/rtl8821ae
    install -m 0644 ${ADDON_FILES_DIR}/sdsd8997_combo_v4.bin ${IMAGE_ROOTFS}/lib/firmware/nxp/sdsd8997_combo_v4.bin
    install -m 0644 ${ADDON_FILES_DIR}/pcieuart8997_combo_v4_mxm5x17391.bin ${IMAGE_ROOTFS}/lib/firmware/nxp/pcieuart8997_combo_v4_mxm5x17391.bin
    install -m 0755 ${ADDON_FILES_DIR}/quectel-CM ${IMAGE_ROOTFS}/usr/bin/quectel-CM
    install -m 0755 ${ADDON_FILES_DIR}/adv-quectel-CM ${IMAGE_ROOTFS}/usr/bin/adv-quectel-CM
    mkdir -p ${IMAGE_ROOTFS}/lib/firmware/qca
    install -m 0644 ${ADDON_FILES_DIR}/nvm_usb_00000302.bin ${IMAGE_ROOTFS}/lib/firmware/qca/nvm_usb_00000302.bin
    install -m 0644 ${ADDON_FILES_DIR}/rampatch_usb_00000302.bin ${IMAGE_ROOTFS}/lib/firmware/qca/rampatch_usb_00000302.bin
    # Ensure demo directory exists before installing demos.json
    mkdir -p ${IMAGE_ROOTFS}/home/root/.nxp-demo-experience
    install -m 0644 ${ADDON_FILES_DIR}/demos.json ${IMAGE_ROOTFS}/home/root/.nxp-demo-experience/demos.json
    mkdir -p ${IMAGE_ROOTFS}/lib/modules/rtl8822cu
    install -m 0755 ${ADDON_FILES_DIR}/8822cu.ko ${IMAGE_ROOTFS}/lib/modules/rtl8822cu
    mkdir -p ${IMAGE_ROOTFS}/lib/firmware/rtl_bt
    install -m 0755 ${ADDON_FILES_DIR}/rtl8822cu_fw.bin ${IMAGE_ROOTFS}/lib/firmware/rtl_bt
    install -m 0755 ${ADDON_FILES_DIR}/rtl8822cu_config.bin ${IMAGE_ROOTFS}/lib/firmware/rtl_bt
    mkdir -p ${IMAGE_ROOTFS}/etc/systemd/network/
    install -m 0755 ${ADDON_FILES_DIR}/10-wireless.network ${IMAGE_ROOTFS}/etc/systemd/network/10-wireless.network
}
