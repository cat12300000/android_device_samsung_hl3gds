# TWRP device tree for Samsung Galaxy Note 3 Neo Duos (SM-N7502)

Codename: `hl3gds`

Hardware: Qualcomm MSM8226/MSM8228, 720x1280, Android 4.3 base, Linux 3.4.

## Sources

- Kernel and DTB extracted from the stock SM-N7502 boot/recovery images supplied for this device.
- Stock recovery fstab and build properties used as hardware reference.
- Recovery source comes from the official TWRP minimal manifests.

No third-party device tree files are included.

## Prebuilt checksums

```text
zImage  MD5 f3fb077167b04df282043b4530557251
zImage  SHA256 8b1723f86ec8ada65b6eccb10d40c8fac062f23280eb0a96383ec165119248ee
dtb     MD5 79f9410b09c868d1eff7f6eb5ffcf8a8
dtb     SHA256 95ed238941aadb95fdc875b44933c65f13fa960f9da4ee21ecfd3350f501859a
```

## Build

The GitHub Actions workflow defaults to TWRP 9.0 for the first build; TWRP 11 is
available from the manual dispatch menu.

### TWRP 11 (AOSP minimal manifest)

```sh
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-11
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags

mkdir -p device/samsung
cp -a /path/to/android_device_samsung_hl3gds device/samsung/hl3gds

export ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
lunch twrp_hl3gds-eng
mka recoveryimage

python3 device/samsung/hl3gds/tools/patch_samsung_dt_size.py \
  out/target/product/hl3gds/recovery.img \
  device/samsung/hl3gds/prebuilt/dtb

sh device/samsung/hl3gds/tools/append_samsung_trailer.sh \
  out/target/product/hl3gds/recovery.img
```

### TWRP 9 (Omni minimal manifest)

```sh
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_omni.git -b twrp-9.0
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags

mkdir -p device/samsung
cp -a /path/to/android_device_samsung_hl3gds device/samsung/hl3gds

export ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
lunch omni_hl3gds-eng
mka recoveryimage

python3 device/samsung/hl3gds/tools/patch_samsung_dt_size.py \
  out/target/product/hl3gds/recovery.img \
  device/samsung/hl3gds/prebuilt/dtb

sh device/samsung/hl3gds/tools/append_samsung_trailer.sh \
  out/target/product/hl3gds/recovery.img
```

TWRP 9 needs host `lzma`; install `xz-utils` if it is missing.

## Notes

- The recovery partition is treated as 10 MiB, inferred from the stock recovery
  image size. Confirm the actual size from the device PIT before flashing. If the
  image is too large, disable `TW_INCLUDE_CRYPTO` or build the TWRP 9 variant.
- The Samsung bootloader expects `SEANDROIDENFORCE` at the end of boot images.
  The build system does not add it automatically; the helper script appends the
  16-byte marker only, not the stock 256-byte signature block. This is the usual
  Samsung compatibility path for custom recovery images.
- The TWRP 11 AOSP `mkbootimg` writes a standard v0 header without Samsung's
  `dt_size` field. The workflow patches offset `0x28` with the DTB size before
  appending the trailer. The TWRP 9 `--dt` path already writes this field.
- The image is unsigned. Flashing is at your own risk.
- GitHub Actions workflow `.github/workflows/build-twrp.yml` supports both
  `twrp-11` and `twrp-9.0` via manual dispatch.

## Credits

- Team Win Recovery Project
- Samsung, for the stock device firmware used as the hardware reference
