PRODUCT_MAKEFILES :=
COMMON_LUNCH_CHOICES :=

ifneq ($(wildcard vendor/twrp/config/common.mk),)
    PRODUCT_MAKEFILES += $(LOCAL_DIR)/twrp_hl3gds.mk
    COMMON_LUNCH_CHOICES += twrp_hl3gds-eng twrp_hl3gds-userdebug
endif

ifneq ($(wildcard vendor/omni/config/common.mk),)
    PRODUCT_MAKEFILES += $(LOCAL_DIR)/omni_hl3gds.mk
    COMMON_LUNCH_CHOICES += omni_hl3gds-eng omni_hl3gds-userdebug
endif
