DEVICE_PATH := device/samsung/hl3gds

# Build environment
ALLOW_MISSING_DEPENDENCIES := true

# Architecture
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a7
TARGET_CPU_SMP := true
TARGET_BOARD_PLATFORM := msm8226
TARGET_BOARD_PLATFORM_GPU := qcom-adreno305

# Bootloader
BOARD_VENDOR := samsung
TARGET_BOOTLOADER_BOARD_NAME := MSM8226
TARGET_NO_BOOTLOADER := true

# Kernel
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_IMAGE_NAME := zImage
BOARD_KERNEL_CMDLINE := console=null androidboot.console=null androidboot.hardware=qcom user_debug=31 maxcpus=4 msm_rtb.filter=0x3F
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
ifneq ($(filter omni_hl3gds,$(TARGET_PRODUCT)),)
BOARD_MKBOOTIMG_ARGS := --kernel_offset 0x00008000 --ramdisk_offset 0x02000000 --tags_offset 0x01e00000 --dt $(DEVICE_PATH)/prebuilt/dtb
else
BOARD_MKBOOTIMG_ARGS := --kernel_offset 0x00008000 --ramdisk_offset 0x02000000 --tags_offset 0x01e00000 --dtb $(DEVICE_PATH)/prebuilt/dtb --header_version 0
endif
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/zImage

# Filesystems
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_SUPPRESS_SECURE_ERASE := true
TARGET_USERIMAGES_USE_EXT4 := true

# Partitions
# Set this to the REAL size of your recovery partition (check /proc/partitions
# on the phone: blocks x 1024). 10485760 = 10 MB.
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 10485760
# Required by the size check on Android 7.1 and older branches
# (131072 = 64 x 2048 page size, the usual value for these Samsung devices)
BOARD_FLASH_BLOCK_SIZE := 131072

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"
TARGET_RECOVERY_QCOM_RTC_FIX := true
TARGET_OTA_ASSERT_DEVICE := hl3gds
RECOVERY_SDCARD_ON_DATA := true

# TWRP
TW_THEME := portrait_hdpi
TARGET_SCREEN_WIDTH := 720
TARGET_SCREEN_HEIGHT := 1280
TW_BRIGHTNESS_PATH := "/sys/class/leds/lcd-backlight/brightness"
TW_MAX_BRIGHTNESS := 255
TW_DEFAULT_BRIGHTNESS := 162
TW_INTERNAL_STORAGE_PATH := "/data/media"
TW_INTERNAL_STORAGE_MOUNT_POINT := "data"
TW_EXTERNAL_STORAGE_PATH := "/external_sd"
TW_EXTERNAL_STORAGE_MOUNT_POINT := "external_sd"
TW_MTP_DEVICE := "/dev/mtp_usb"
TW_HAS_DOWNLOAD_MODE := true
BOARD_HAS_NO_REAL_SDCARD := false

# Features kept
TW_INCLUDE_BATTERY_PERCENT := true
# exFAT fuse removed for size (exFAT SD cards will not mount)
#TW_INCLUDE_FUSE_EXFAT := true
TW_NO_USB_STORAGE := false          # needed for OTG
TW_EXCLUDE_DEFAULT_USB_INIT := false
TW_USE_TOOLBOX := true
TW_OEM_BUILD := true
TW_DEFAULT_LANGUAGE := en
TW_NO_SCREEN_TIMEOUT := true
TW_NO_SCREEN_BLANK := true
TW_IGNORE_MISC_UNMOUNT := true

# Size reduction (only flags that actually exist)
TW_EXCLUDE_SUPERSU := true
TW_EXCLUDE_TWRPAPP := true
TW_EXCLUDE_NANO := true
TW_EXCLUDE_ENCRYPTED_BACKUPS := true
TW_INCLUDE_NTFS_3G := false
TW_INCLUDE_CRYPTO := false
LZMA_RAMDISK_TARGETS := recovery
TW_NO_EXFAT_FUSE := true
#TW_EXCLUDE_MTP := true
#TW_EXCLUDE_BASH := true
