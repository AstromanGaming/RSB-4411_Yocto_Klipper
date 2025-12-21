DESCRIPTION = "Debian ARM bare-metal toolchain (gcc, binutils, newlib) libraries for YoctianOS ARM hosts"
PN = "lib-yoctianos-arm-none-eabi"
PV = "DEV"
PR = "r1"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=c9c87ca016344f2a98c6b0802912f8ee"

SRC_URI = " \
    http://ftp.debian.org/debian/pool/main/g/glibc/libc6_2.41-12_armhf.deb;name=libc6 \
    http://ftp.debian.org/debian/pool/main/g/gcc-14/libgcc-s1_14.2.0-19_armhf.deb;name=libgcc-s1 \
    http://ftp.debian.org/debian/pool/main/g/gmp/libgmp10_6.3.0+dfsg-3_armhf.deb;name=libgmp10 \
    http://ftp.debian.org/debian/pool/main/i/isl/libisl23_0.27-1_armhf.deb;name=libisl23 \
    http://ftp.debian.org/debian/pool/main/m/mpclib3/libmpc3_1.3.1-1+b3_armhf.deb;name=libmpc3 \
    http://ftp.debian.org/debian/pool/main/m/mpfr4/libmpfr6_4.2.2-1_armhf.deb;name=libmpfr6 \
    http://ftp.debian.org/debian/pool/main/g/gcc-14/libstdc++6_14.2.0-19_armhf.deb;name=libstdc++6 \
    http://ftp.debian.org/debian/pool/main/g/gcc-14/gcc-14-base_14.2.0-19_armhf.deb;name=gcc-14-base \
    http://ftp.debian.org/debian/pool/main/z/zlib/zlib1g_1.3.dfsg+really1.3.1-1+b1_armhf.deb;name=zlib1g \
    http://ftp.debian.org/debian/pool/main/libz/libzstd/libzstd1_1.5.7+dfsg-1_armhf.deb;name=libzstd1 \
    http://ftp.debian.org/debian/pool/main/n/newlib/libnewlib-dev_4.5.0.20241231-1_all.deb;name=libnewlib-dev \
    file://LICENSE \
"

SRC_URI[libc6.sha256sum] = "b0408267a81aac091bdd12829bad5b5f36d88a6bac1d1b08f8f4f508dbfa5930"
SRC_URI[libgcc-s1.sha256sum] = "25910c3a0bce3985e388de445244578b7922dc670c9bba1c8673779b89447873"
SRC_URI[libgmp10.sha256sum] = "b74d0fa0aa9d1e2f7addae5d3c235fc881e1507d98559ab158362bef56877a56"
SRC_URI[libisl23.sha256sum] = "6dbb4b7620d7f220717ed710ebc8a62af5a691131edb9d6d63dbf10fec3b3b86"
SRC_URI[libmpc3.sha256sum] = "d2efdeb151ae18e07d41b08815a9f003c2d93beec13dbcc2b23794a7e6d69665"
SRC_URI[libmpfr6.sha256sum] = "75b15b85c73d2703b208ac47e5d4f27b81cfbc137e1e39359bb911f8d7c0c482"
SRC_URI[libstdc++6.sha256sum] = "9c82eecc30961a3da3e062c0dba8ce076736059f4b8e7794c803985e75aea48b"
SRC_URI[gcc-14-base.sha256sum] = "0f702fdd5e5471efda9fece892e09ce73e3447968083e1f8c341f8b66b1fb34"
SRC_URI[zlib1g.sha256sum] = "81c55a59e1570477ecef6a449bf6dce44dad67ba4ce9e04760451d4cfe200534"
SRC_URI[libzstd1.sha256sum] = "da5238dd84fc51f782f39d435821bff556409b3dbc82d232e4e81f427fb1ca65"
SRC_URI[libnewlib-dev.sha256sum] = "feb2ed49a464b0346e42c3506088a41025273bff5f8e6bc5777afeac3704b3c1"

S = "${WORKDIR}"

do_install() {
    install -d ${D}/opt/yoctianos-arm-none-eabi

    # Copy extracted content
    if [ -d "${S}/usr" ]; then
        cp -a ${S}/usr/* ${D}/opt/yoctianos-arm-none-eabi/
    else
        echo "ERROR: No extracted usr/ directory found in WORKDIR"
        exit 1
    fi

    # Fix ownership to avoid host contamination
    chown -R root:root ${D}/opt/yoctianos-arm-none-eabi
}

FILES:${PN} = " \
    /opt/yoctianos-arm-none-eabi \
"

# This is a prebuilt external toolchain, not a target package
INHIBIT_DEFAULT_DEPS = "1"
RDEPENDS:${PN} = ""
RRECOMMENDS:${PN} = ""

# Disable QA checks that do not apply to external toolchains
INSANE_SKIP:${PN} += "already-stripped staticdev dev-so file-rdeps ldflags"
