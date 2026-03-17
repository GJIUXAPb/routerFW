Добрый день.
Спасибо за проект.

Попробовал OpenWrtFW Builder под Ubuntu 20.04.6
Добавил визардом свои роутеры. Получил следующее:
[ 1] cudy_wbr3000uax_v1_ubootmod_25120_ow_full mipsel_24kc [F····· | ·· ··]
[ 6] xiaomi_mi_router_ax3000t_24105_ow_full mipsel_24kc [F····· | ·· ··]

Оба раза получил mipsel_24kc.

Созданные визардом профили:

# === Profile for cudy_wbr3000uax-v1-ubootmod (OpenWrt 25.12.0) ===

PROFILE_NAME="cudy_wbr3000uax_v1_ubootmod_25120_ow_full"
TARGET_PROFILE="cudy_wbr3000uax-v1-ubootmod"

COMMON_LIST="apk-mbedtls base-files ca-bundle dnsmasq dropbear firewall4 fitblk fstools kmod-c>

# === IMAGE BUILDER CONFIG
IMAGEBUILDER_URL="https://downloads.open…mediatek/filogic/open>
#CUSTOM_KEYS="https://fantastic-pack…0/53ff2b6672243d28.pu>
#CUSTOM_REPOS="src/gz fantastic_luci https://fantastic-pack…/packages/releases/24>
#src/gz fantastic_packages https://fantastic-pack…releases/24.10/packag>
#src/gz fantastic_special https://fantastic-pack…eleases/24.10/package>
#DISABLED_SERVICES="transmission-daemon minidlna"
IMAGE_PKGS="$COMMON_LIST"
#IMAGE_EXTRA_NAME="custom"

# === Extra config options
#ROOTFS_SIZE="512"
#KERNEL_SIZE="64"

# === SOURCE BUILDER CONFIG
SRC_REPO="https://github.com/openwrt/openwrt.git"
SRC_BRANCH="v25.12.0"
SRC_TARGET="mediatek"
SRC_SUBTARGET="filogic"
SRC_ARCH="mipsel_24kc"
SRC_PACKAGES="$IMAGE_PKGS"
# Number of cores, "safe" (all-1), or "debug" for single-core verbose build
SRC_CORES="safe"

## SPACE SAVING (For 4MB / 8MB flash devices)
# - CONFIG_LUCI_SRCDIET=y -> Compresses Lua/JS in LuCI (saves ~100-200KB)
# - CONFIG_IPV6=n -> Completely removes IPv6 support (saves ~300KB)
# - CONFIG_KERNEL_DEBUG_INFO=n -> Removes debugging information from the kernel
# - CONFIG_STRIP_KERNEL_EXPORTS=y -> Strips kernel export symbols (if no external kmods nee>
## FILE SYSTEMS (For SD cards / x86 / NanoPi)
# By default, SquashFS (Read-Only) is created. EXT4 is recommended for SBCs.
# - CONFIG_TARGET_ROOTFS_SQUASHFS=n -> Disable SquashFS

# === Profile for xiaomi_mi-router-ax3000t (OpenWrt 24.10.5) ===

PROFILE_NAME="xiaomi_mi_router_ax3000t_24105_ow_full"
TARGET_PROFILE="xiaomi_mi-router-ax3000t"

COMMON_LIST="base-files ca-bundle dnsmasq dropbear firewall4 fitblk fstools kmod-crypto-hw-saf>

# === IMAGE BUILDER CONFIG
IMAGEBUILDER_URL="https://downloads.open…mediatek/filogic/open>
#CUSTOM_KEYS="https://fantastic-pack…0/53ff2b6672243d28.pu>
#CUSTOM_REPOS="src/gz fantastic_luci https://fantastic-pack…/packages/releases/24>
#src/gz fantastic_packages https://fantastic-pack…releases/24.10/packag>
#src/gz fantastic_special https://fantastic-pack…eleases/24.10/package>
#DISABLED_SERVICES="transmission-daemon minidlna"
IMAGE_PKGS="$COMMON_LIST"
#IMAGE_EXTRA_NAME="custom"

# === Extra config options
#ROOTFS_SIZE="512"
#KERNEL_SIZE="64"

# === SOURCE BUILDER CONFIG
SRC_REPO="https://github.com/openwrt/openwrt.git"
SRC_BRANCH="v24.10.5"
SRC_TARGET="mediatek"
SRC_SUBTARGET="filogic"
SRC_ARCH="mipsel_24kc"
SRC_PACKAGES="$IMAGE_PKGS"
# Number of cores, "safe" (all-1), or "debug" for single-core verbose build
SRC_CORES="safe"

## SPACE SAVING (For 4MB / 8MB flash devices)
# - CONFIG_LUCI_SRCDIET=y -> Compresses Lua/JS in LuCI (saves ~100-200KB)
# - CONFIG_IPV6=n -> Completely removes IPv6 support (saves ~300KB)
# - CONFIG_KERNEL_DEBUG_INFO=n -> Removes debugging information from the kernel
# - CONFIG_STRIP_KERNEL_EXPORTS=y -> Strips kernel export symbols (if no external kmods nee>
## FILE SYSTEMS (For SD cards / x86 / NanoPi)
# By default, SquashFS (Read-Only) is created. EXT4 is recommended for SBCs.
# - CONFIG_TARGET_ROOTFS_SQUASHFS=n -> Disable SquashFS