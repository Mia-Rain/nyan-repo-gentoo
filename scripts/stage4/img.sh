#!/bin/sh

hexdump_tag_latest="230915-02"
hexdump_dist="bookworm"
hexdump_tag_legacy="210724-01"
hexdump_dist_legacy="bullseye-legacy"
name="chromebook_nyan-armv7l"
suffix="img.gz"
url="https://github.com/hexdump0815/imagebuilder/releases/download"
[ "${legacy}" ] && {
  tag="$hexdump_tag_legacy"
  dist="$hexdump_dist_legacy"
}
: "${tag:=$hexdump_tag_latest}"
: "${dist:=$hexdump_dist}"
name="${name}-${dist}"
url="${url}/${tag}/${name}.${suffix}"
[ -e "${name}.${suffix}" -o "${name}.img" ] || curl -LO -C- --progress-bar "$url"
gunzip "${name}.${suffix}" 2>/dev/null
dd bs=1024k if=/dev/zero count=3000 >> "${name}.img"
# extend the img, adds about 3gb, might be enough
# not enough for a full system but might be enough for a base xorg
# this is for a bootable image, steps for flashing internally are more involved
loopdev="$(losetup --show -fP ${name}.img)"
# this required parted as fdisk can't be easily scripted
# and sfdisk is weird
parted "${loopdev}" rm 4
parted "${loopdev}" mkpart primary ext4 608 6904
yes | mkfs.ext4 "${loopdev}"


umount "$mount"
losetup -d "${loopdev}"
