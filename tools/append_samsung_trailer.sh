#!/bin/sh
set -eu

image="${1:?usage: append_samsung_trailer.sh <recovery.img>}"
marker="SEANDROIDENFORCE"

if [ ! -f "$image" ]; then
    echo "image not found: $image" >&2
    exit 1
fi

if tail -c 272 "$image" | grep -aq "$marker"; then
    echo "$image already has $marker"
    exit 0
fi

printf '%s' "$marker" >> "$image"
echo "appended $marker to $image"
