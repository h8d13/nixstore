#!/bin/sh -e
# One-shot flash to real hardware: size the image to the target disk,
# build it, write it, verify both filesystems. Privileged steps go
# through sudo; image build stays unprivileged.
# Write strategy: GPT+ESP (first 66MiB) in full, because a sparse write
# leaves the previous flash's FAT metadata under the holes; the store
# partition sparse, its metadata is all real bytes in the image and
# fsck verifies the result either way.
# usage: flashdisk.sh <store-root> <device>     e.g. build/archstore /dev/sdb
cd "$(dirname "$0")/../.."
REPO=$PWD

STORE=$1 DEV=$2
[ -n "$STORE" ] && [ -b "$DEV" ] || {
	echo "usage: $0 <store-root> <device>" >&2
	exit 1
}
case $DEV in
*[0-9]) PART="${DEV}p" ;;
*) PART="$DEV" ;;
esac

lsblk -dn -o NAME,SIZE,MODEL,TRAN "$DEV"
printf 'everything on %s will be lost. type the device path to continue: ' "$DEV"
read -r reply
[ "$reply" = "$DEV" ] || { echo "aborted"; exit 1; }

SIZE=$(( $(lsblk -b -dn -o SIZE "$DEV") / 1048576 ))
IMG=$REPO/build/nixarch-disk.img
arch/iso/mkbootdisk.sh "$STORE" "$IMG" "$SIZE"

for p in "${PART}1" "${PART}2"; do
	sudo umount "$p" || true
done

sudo dd if="$IMG" of="$DEV" bs=1M count=66 \
	oflag=direct conv=notrunc status=progress
sudo dd if="$IMG" of="$DEV" bs=1M skip=66 seek=66 \
	oflag=direct conv=sparse,notrunc status=progress
sync
sudo partprobe "$DEV"
sleep 1
sudo fsck.fat -n "${PART}1"
sudo fsck.ext4 -fn "${PART}2"
echo "flashed + verified: $DEV"
