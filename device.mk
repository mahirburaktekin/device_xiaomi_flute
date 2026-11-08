DEVICE_PATH := device/xiaomi/flute

# Vendor tree: stock blob'lar
$(call inherit-product, vendor/xiaomi/flute/flute-vendor.mk)

# Blob'lar VNDK v34'e bağlı
PRODUCT_EXTRA_VNDK_VERSIONS := 34

# Stock: ro.product.first_api_level=35, ro.board.api_level=34 (vendor dondurulmuş)
PRODUCT_SHIPPING_API_LEVEL := 35

# Dinamik bölümler + Virtual A/B (sıkıştırmalı, userspace snapshot, io_uring, xor)
PRODUCT_USE_DYNAMIC_PARTITIONS := true
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/vabc_features.mk)
PRODUCT_VIRTUAL_AB_COMPRESSION_METHOD := lz4

# A/B
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier \
    otapreopt_script \
    checkpoint_gc \
    fastbootd

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=erofs \
    POSTINSTALL_OPTIONAL_system=true

# Tablet, 320 dpi (xhdpi)
PRODUCT_CHARACTERISTICS := tablet
PRODUCT_AAPT_CONFIG := normal large xlarge
PRODUCT_AAPT_PREF_CONFIG := xhdpi
PRODUCT_PRODUCT_PROPERTIES += ro.sf.lcd_density=320

# Emulated storage
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# First-stage fstab (vendor_boot ramdisk) — mi_ext ve overlay satırları çıkarıldı
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.qcom

# GKI kernel (fetch-gki.sh ile indirilir)
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/prebuilt/gki/Image:kernel
