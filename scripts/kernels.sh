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
loopdev="$(losetup --show -fP ${name}.img)"
mkdir -p /usr/local/tmp/boot
mount | grep -q /boot || exit 
mount -o loop,ro ${loopdev}p3 /usr/local/tmp/boot
cp -avnr /usr/local/tmp/boot/* /boot
umount /usr/local/tmp/boot
losetup -d "${loopdev}"
