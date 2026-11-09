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
    fastbootd

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=erofs \
    POSTINSTALL_OPTIONAL_system=true

# Overlay (120 Hz)
PRODUCT_PACKAGES += \
    FrameworksResFlute

# Tablet, 320 dpi (xhdpi)
PRODUCT_CHARACTERISTICS := tablet
PRODUCT_AAPT_CONFIG := normal large xlarge
PRODUCT_AAPT_PREF_CONFIG := xhdpi
PRODUCT_PRODUCT_PROPERTIES += ro.sf.lcd_density=320

# Emulated storage
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# First-stage fstab (vendor_boot ramdisk) — mi_ext ve overlay satırları çıkarıldı
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.qcom \
    $(DEVICE_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.qcom

# GKI kernel (fetch-gki.sh ile indirilir)
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/prebuilt/gki/Image:kernel

# Stock vendor HIDL HAL'leri kullanıyor (shipping 35'te AOSP bunları eklemiyor)
PRODUCT_HIDL_ENABLED := true
PRODUCT_PACKAGES += \
    hwservicemanager \
    android.hidl.allocator@1.0-service \
    android.hidl.memory@1.0-impl

# base_vendor.mk kullanılmıyor (stock vendor dosyaları korunsun diye); gerekenler:
PRODUCT_PACKAGES += \
    adbd.recovery \
    cgroups.recovery.json \
    charger.recovery \
    init_second_stage.recovery \
    ld.config.recovery.txt \
    linker.recovery \
    otacerts.recovery \
    recovery \
    servicemanager.recovery \
    shell_and_utilities_recovery \
    watchdogd.recovery \
    odm-build.prop \
    vendor_compatibility_matrix.xml

# Vendor dondurulmuş: API 34 (stock ile aynı)
PRODUCT_VENDOR_PROPERTIES += ro.board.api_level=34

# SELinux: stock vendor/odm politikası açılışta derlenir (precompiled kullanılmaz),
# genfs etiketleri stock vendor'ın beklediği sürümde kalır.
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/sepolicy/genfs_labels_version.txt:$(TARGET_COPY_OUT_VENDOR)/etc/selinux/genfs_labels_version.txt

# --- Bring-up (GEÇİCİ: ilk boot sonrası kaldır) ---
# adb onay beklemeden açılsın (bootloop'ta logcat alabilmek için),
# izin listesi eksikleri system_server'ı çökertmesin, sadece loglansın.
PRODUCT_PRODUCT_PROPERTIES += \
    ro.adb.secure=0 \
    persist.sys.usb.config=adb \
    ro.control_privapp_permissions=log
