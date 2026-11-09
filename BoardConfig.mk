DEVICE_PATH := device/xiaomi/flute

# Cihazdan okundu (fastboot getvar partition-size:*)
BOARD_SUPER_PARTITION_SIZE := 0x2E0000000
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 0x6400000

ifneq ($(words $(wildcard $(DEVICE_PATH)/prebuilt/gki/Image $(DEVICE_PATH)/prebuilt/gki/system_dlkm.img)),2)
$(error GKI eksik (Image ve system_dlkm.img gerekli): device/xiaomi/flute/fetch-gki.sh çalıştır)
endif
# ---------------------------------------------------------------

# Mimari: SM7635 (volcano), yalnızca arm64
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a76
TARGET_SUPPORTS_64_BIT_APPS := true

# Platform
TARGET_BOARD_PLATFORM := volcano
TARGET_BOOTLOADER_BOARD_NAME := volcano
TARGET_NO_BOOTLOADER := true
TARGET_NO_KERNEL := false

# Boot imajları (header v4, GKI + init_boot)
BOARD_BOOT_HEADER_VERSION := 4
BOARD_INIT_BOOT_HEADER_VERSION := 4
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_BASE := 0x00000000
BOARD_MKBOOTIMG_ARGS += \
    --header_version $(BOARD_BOOT_HEADER_VERSION) \
    --kernel_offset 0x00008000 \
    --ramdisk_offset 0x01000000 \
    --tags_offset 0x00000100 \
    --dtb_offset 0x01f00000
BOARD_MKBOOTIMG_INIT_ARGS += --header_version $(BOARD_INIT_BOOT_HEADER_VERSION)
BOARD_RAMDISK_USE_LZ4 := true

# Stock vendor_boot cmdline ve bootconfig
BOARD_KERNEL_CMDLINE := video=vfb:640x400,bpp=32,memsize=3072000 bootconfig
BOARD_BOOTCONFIG := \
    androidboot.hardware=qcom \
    androidboot.memcg=1 \
    androidboot.usbcontroller=4e00000.dwc3 \
    androidboot.load_modules_parallel=true

# DTB (vendor_boot) ve DTBO (stock'tan)
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/prebuilt/dtb
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/dtbo.img

# Bölüm boyutları (stock dump boyutları)
BOARD_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 8388608
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_DTBOIMG_PARTITION_SIZE := 31457280

# Recovery: ayrı recovery_a/b bölümü var (stock fstab)
BOARD_USES_RECOVERY_AS_BOOT := false
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.qcom
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USERIMAGES_USE_EXT4 := true

# vendor_boot modülleri (330 adet, .ko'lar vendor tree'den gelir)
FLUTE_VENDOR_RAMDISK_MODULES := vendor/xiaomi/flute/proprietary/vendor_ramdisk/lib/modules
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(wildcard $(FLUTE_VENDOR_RAMDISK_MODULES)/*.ko)
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/modules/vendor_boot.modules.load))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/modules/vendor_boot.modules.load.recovery))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_BLOCKLIST_FILE := $(DEVICE_PATH)/modules/vendor_boot.modules.blocklist

# system_dlkm: GKI modülleri, kernel ile aynı GKI build'inden olmalı
# Google GKI system_dlkm.img ext4 (stock fstab ext4 ve erofs satırlarının ikisini de içeriyor)
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
# Google GKI system_dlkm.img (/system_dlkm/lib/modules/<kver>/modules.load)
BOARD_PREBUILT_SYSTEM_DLKMIMAGE := $(DEVICE_PATH)/prebuilt/gki/system_dlkm.img

# Dosya sistemleri
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_USES_METADATA_PARTITION := true
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

# Vendor/odm/vendor_dlkm: stock blob'lardan (vendor/xiaomi/flute) derlenir
FLUTE_VENDOR_DLKM := vendor/xiaomi/flute/proprietary/vendor_dlkm/lib/modules
BOARD_VENDOR_KERNEL_MODULES := $(wildcard $(FLUTE_VENDOR_DLKM)/*.ko)
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(notdir $(strip $(shell cat $(FLUTE_VENDOR_DLKM)/modules.load 2>/dev/null)))
BOARD_VENDOR_KERNEL_MODULES_BLOCKLIST_FILE := $(wildcard $(FLUTE_VENDOR_DLKM)/modules.blocklist)

# Vendor API 34 (blob'lar Android 14 SDK ile derlenmiş)
# BOARD_API_LEVEL elle ayarlanamaz (AOSP 16); vendor seviyesi device.mk'de ro.board.api_level=34
BOARD_SHIPPING_API_LEVEL := 34
VENDOR_SECURITY_PATCH := 2026-05-05

# Sepolicy: çalışma anında stock vendor/odm politikası (blob) kullanılır.
# Buradaki dizin yalnızca imajları stock etiketleriyle etiketlemek için tip tanımları içerir.
BOARD_SEPOLICY_VERS := 34.0
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
# Stock vendor politikasının istediği Qualcomm system_ext tipleri.
# 34.0 eşlemesi (typeattributeset X_34_0) vendor tree'de vendor_sepolicy.cil sonunda:
# system_ext eşleme dosyasına konunca 34.0_compat_test, prebuilt dizin verilince treble testleri patlıyor.
SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/qcom_system_ext/public

# Dosya sahiplikleri/yetkileri (stock fs_config_files'tan)
TARGET_FS_CONFIG_GEN := $(DEVICE_PATH)/config.fs

# VINTF (stock manifest; ayrı SKU manifest'i yok — aynı dosya iki kez kurulursa HAL tanımları çiftlenir)
DEVICE_MANIFEST_FILE := $(DEVICE_PATH)/vintf/manifest_volcano.xml
DEVICE_MATRIX_FILE := $(DEVICE_PATH)/vintf/compatibility_matrix.xml

# Properties (stock)
TARGET_VENDOR_PROP := $(DEVICE_PATH)/vendor.prop
TARGET_ODM_PROP := $(DEVICE_PATH)/odm.prop

# Blob kopyası için gerekli
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_VINTF_PRODUCT_COPY_FILES := true
BUILD_BROKEN_DUP_SYSPROP := true
# Stock vendor dosyaları (sh, toybox, selinux, passwd, fs_config...) AOSP modülleriyle
# aynı yola kuruluyor; kopya (stock) kazanır.
BUILD_BROKEN_DUP_RULES := true

# Dinamik bölümler (super)
BOARD_SUPER_PARTITION_GROUPS := xiaomi_dynamic_partitions
BOARD_XIAOMI_DYNAMIC_PARTITIONS_SIZE := $(shell echo $$(( $(BOARD_SUPER_PARTITION_SIZE) - 4194304 )))
BOARD_XIAOMI_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    system system_ext product vendor odm vendor_dlkm system_dlkm

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot init_boot vendor_boot dtbo recovery \
    vbmeta vbmeta_system \
    system system_ext product vendor odm vendor_dlkm system_dlkm

# AVB (test anahtarları; bring-up için verity/verification kapalı)
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
BOARD_AVB_VBMETA_SYSTEM := system system_ext product
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 1
BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 2

# SELinux: stock vendor/odm politikası açılışta derlensin (precompiled yok)
PRODUCT_PRECOMPILED_SEPOLICY := false
