# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)

# Inherit some common PixelOS stuff.
$(call inherit-product, vendor/custom/config/common_full_tablet_wifionly.mk)
TARGET_SCREEN_WIDTH := 1600

# Inherit from flute device
$(call inherit-product, device/xiaomi/flute/device.mk)

PRODUCT_NAME := custom_flute
PRODUCT_DEVICE := flute
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := 25099RP13G
PRODUCT_MANUFACTURER := Xiaomi

# Maintainer
PRODUCT_PRODUCT_PROPERTIES += \
    ro.custom.maintainer=vaharai
