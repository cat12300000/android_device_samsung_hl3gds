#!/usr/bin/env python3
"""Repack a TWRP recovery.img so it boots on the hl3gds 3.4.0 stock kernel.

The Android 6.0 init in the TWRP ramdisk loops on this Samsung kernel (it ships
an SELinux policy v30 the kernel cannot load, and the kernel has no selinux=0
parameter). This script keeps the TWRP userspace (recovery, adbd, libs, tools)
but swaps in the stock Android 4.3 init, ueventd files, SELinux files and a
simplified init.rc taken from the device's own stock recovery (hybrid/).

usage: make_hybrid_recovery.py <recovery.img> <hybrid-dir> [--dtb prebuilt/dtb] [--fstab recovery.fstab]
                               [--max-size 10485760] [--out other.img]
The image is rewritten in place unless --out is given. Idempotent.
"""
import argparse, hashlib, lzma, os, stat, struct, sys

OVERLAY = ["init", "init.rc", "ueventd.rc", "ueventd.qcom.rc", "sepolicy",
           "file_contexts", "property_contexts", "seapp_contexts",
           "sepolicy_version", "sbin/powerctl"]
# TWRP 6.0 boot scripts that the stock-style init.rc does not import
DROP = {"init.recovery.hlthchrg.rc", "init.recovery.mksh.rc",
        "init.recovery.service.rc", "init.recovery.usb.rc"}
# The kernel gives adbd AT_SECURE (SELinux domain transition), so its static
# bionic strips LD_LIBRARY_PATH and `adb shell` cannot find libc++.so in /sbin.
# The 6.0 linker searches /vendor/lib by default, so point that at /sbin.
LINKS = {"vendor/lib": "/sbin"}
EXEC = {"init", "init.rc", "sbin/powerctl"}  # mode 0750 like the stock ramdisk
MARKER = b"SEANDROIDENFORCE"


def die(msg):
    sys.exit("make_hybrid_recovery: error: " + msg)


def cpio_read(d):
    o, ents = 0, []
    while True:
        if d[o:o + 6] != b"070701":
            die("ramdisk is not a newc cpio archive")
        f = [int(d[o + 6 + i * 8:o + 14 + i * 8], 16) for i in range(13)]
        mode, uid, gid, fs, nsz = f[1], f[2], f[3], f[6], f[11]
        name = d[o + 110:o + 109 + nsz].decode()
        p = (o + 110 + nsz + 3) & ~3
        data = d[p:p + fs]
        o = (p + fs + 3) & ~3
        if name == "TRAILER!!!":
            return ents
        ents.append([name, mode, uid, gid, data])


def cpio_write(ents):
    out, ino = bytearray(), 1
    for n, m, u, g, dt in ents + [["TRAILER!!!", 0, 0, 0, b""]]:
        nb = n.encode() + b"\0"
        out += b"070701" + b"".join(b"%08X" % x for x in
                (ino, m, u, g, 1, 0, len(dt), 0, 0, 0, 0, len(nb), 0))
        ino += 1
        out += nb
        out += b"\0" * (-len(out) % 4)
        out += dt
        out += b"\0" * (-len(out) % 4)
    return bytes(out)


def lzma_alone(raw):
    # same stream `xz --format=lzma -9` writes: lc3 lp0 pb2, 64 MiB dictionary
    return lzma.compress(raw, format=lzma.FORMAT_ALONE,
                         filters=[{"id": lzma.FILTER_LZMA1, "preset": 9}])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image"); ap.add_argument("hybrid")
    ap.add_argument("--dtb"); ap.add_argument("--out"); ap.add_argument("--fstab")
    ap.add_argument("--max-size", type=int, default=10485760)
    a = ap.parse_args()

    d = open(a.image, "rb").read()
    if d[:8] != b"ANDROID!":
        die("not an Android boot image")
    ks, ka, rs, ra, ss, sa, ta, ps, dts, unused = struct.unpack("<10I", d[8:48])
    name, cmd = d[48:64], d[64:576].split(b"\0")[0]
    pg = lambda n: (n + ps - 1) // ps * ps
    o = ps
    kernel = d[o:o + ks]; o += pg(ks)
    ramdisk = d[o:o + rs]; o += pg(rs)
    o += pg(ss)
    if dts:
        dtb = d[o:o + dts]; o += pg(dts)
    else:  # build left dt_size at 0: take the DTB from the tree
        if not a.dtb:
            die("dt_size is 0 in the image; pass --dtb prebuilt/dtb")
        dtb = open(a.dtb, "rb").read()
        if d[o:o + 4] == b"QCDT":  # an unlisted copy follows the ramdisk: skip it
            o += pg(len(dtb))
    tail = d[o:]
    if ss:
        die("second-stage image present, unsupported")

    if ramdisk[:2] == b"\x1f\x8b":
        import gzip; raw = gzip.decompress(ramdisk)
    else:
        raw = lzma.LZMADecompressor(format=lzma.FORMAT_ALONE).decompress(ramdisk)
    ents = [e for e in cpio_read(raw) if e[0] not in DROP]
    have = {e[0]: e for e in ents}
    for n in OVERLAY:
        p = os.path.join(a.hybrid, n)
        if not os.path.isfile(p):
            die("missing overlay file " + p)
        data = open(p, "rb").read()
        if n in have:
            have[n][4] = data
        else:
            e = [n, stat.S_IFREG | (0o750 if n in EXEC else 0o644), 0, 0, data]
            ents.append(e); have[n] = e
    for link, target in LINKS.items():
        d0 = link.rsplit("/", 1)[0]
        if d0 not in have:
            e = [d0, stat.S_IFDIR | 0o755, 0, 0, b""]
            ents.append(e); have[d0] = e
        if link in have:
            have[link][1:5] = [stat.S_IFLNK | 0o777, 0, 0, target.encode()]
        else:
            e = [link, stat.S_IFLNK | 0o777, 0, 0, target.encode()]
            ents.append(e); have[link] = e
    if a.fstab:  # keep /etc/recovery.fstab in sync with the tree's recovery.fstab
        if "etc/recovery.fstab" not in have:
            die("ramdisk has no etc/recovery.fstab")
        have["etc/recovery.fstab"][4] = open(a.fstab, "rb").read()
    new = lzma_alone(cpio_write(ents))

    if b"enforcing=0" not in cmd.split():
        cmd += b" enforcing=0"  # this kernel has no selinux=0, but takes enforcing=0
    if len(cmd) >= 512:
        die("command line too long")

    hdr = b"ANDROID!" + struct.pack("<10I", len(kernel), ka, len(new), ra, 0, sa,
                                    ta, ps, len(dtb), 0)
    hdr += name + cmd.ljust(512, b"\0")
    h = hashlib.sha1()
    for part in (kernel, new, b"", dtb):
        h.update(part); h.update(struct.pack("<I", len(part)))
    hdr = (hdr + h.digest().ljust(32, b"\0")).ljust(ps, b"\0")
    pad = lambda b: b + b"\0" * (-len(b) % ps)
    out = hdr + pad(kernel) + pad(new) + pad(dtb) + tail

    if len(out) > a.max_size:
        die("image is %d bytes, limit %d (%d over)" % (len(out), a.max_size,
                                                        len(out) - a.max_size))
    open(a.out or a.image, "wb").write(out)
    print("hybrid recovery written: %d bytes (limit %d), ramdisk %d bytes"
          % (len(out), a.max_size, len(new)))


if __name__ == "__main__":
    main()
