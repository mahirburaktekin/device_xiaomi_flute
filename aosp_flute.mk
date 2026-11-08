# Saf AOSP, yalnızca 64-bit (stock: zygote64, abilist32 boş)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_system.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/handheld_system_ext.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/telephony_system_ext.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_product.mk)

$(call inherit-product, device/xiaomi/flute/device.mk)

PRODUCT_NAME := aosp_flute
PRODUCT_DEVICE := flute
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := 25099RP13G
PRODUCT_MANUFACTURER := Xiaomi
