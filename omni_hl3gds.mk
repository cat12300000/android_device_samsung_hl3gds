$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call inherit-product, vendor/omni/config/common.mk)
$(call inherit-product, device/samsung/hl3gds/device_hl3gds.mk)

PRODUCT_NAME := omni_hl3gds
