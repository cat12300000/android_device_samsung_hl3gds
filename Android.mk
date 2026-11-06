HL3GDS_PATH := $(call my-dir)
LOCAL_PATH := $(HL3GDS_PATH)

include $(call all-makefiles-under,$(LOCAL_PATH))

# Hybrid recovery: the Android 6.0 init in the TWRP ramdisk loops on this
# Samsung 3.4.0 kernel. After recovery.img is built, rewrite it with the stock
# 4.3 init + boot scripts from hybrid/ (see tools/make_hybrid_recovery.py).
# If this hook misbehaves, delete the block and run the script from CI instead:
#   python3 tools/make_hybrid_recovery.py <out>/recovery.img hybrid \
#       --dtb prebuilt/dtb --fstab recovery.fstab
ifneq ($(filter hl3gds,$(TARGET_DEVICE)),)
HL3GDS_HYBRID_STAMP := $(PRODUCT_OUT)/obj/hl3gds_hybrid_recovery.stamp

$(HL3GDS_HYBRID_STAMP): $(PRODUCT_OUT)/recovery.img \
		$(HL3GDS_PATH)/tools/make_hybrid_recovery.py \
		$(HL3GDS_PATH)/recovery.fstab \
		$(wildcard $(HL3GDS_PATH)/hybrid/*) \
		$(wildcard $(HL3GDS_PATH)/hybrid/sbin/*)
	@echo "hl3gds: building hybrid recovery (stock 4.3 init)"
	$(hide) python3 $(HL3GDS_PATH)/tools/make_hybrid_recovery.py \
		$(PRODUCT_OUT)/recovery.img $(HL3GDS_PATH)/hybrid \
		--dtb $(HL3GDS_PATH)/prebuilt/dtb --fstab $(HL3GDS_PATH)/recovery.fstab
	$(hide) mkdir -p $(dir $@)
	$(hide) touch $@

.PHONY: recoveryimage
recoveryimage: $(HL3GDS_HYBRID_STAMP)
endif
