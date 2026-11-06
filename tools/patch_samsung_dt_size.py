#!/usr/bin/env python3
import os
import struct
import sys

DT_SIZE_OFFSET = 0x28
DT_SIZE_RESERVED_OFFSET = 0x2C


def fail(message):
    raise SystemExit(f"error: {message}")


def main():
    if len(sys.argv) != 3:
        fail("usage: patch_samsung_dt_size.py <boot-image> <dtb>")

    image_path, dtb_path = sys.argv[1:]
    dtb_size = os.path.getsize(dtb_path)
    if dtb_size <= 0:
        fail("DTB is empty")

    with open(image_path, "r+b") as image:
        header = image.read(0x30)
        if len(header) != 0x30 or header[:8] != b"ANDROID!":
            fail("not an Android boot image")

        image.seek(DT_SIZE_OFFSET)
        image.write(struct.pack("<I", dtb_size))
        image.seek(DT_SIZE_RESERVED_OFFSET)
        image.write(struct.pack("<I", 0))

    print(f"patched {image_path}: dt_size={dtb_size}")


if __name__ == "__main__":
    main()
