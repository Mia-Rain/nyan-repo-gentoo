#!/bin/sh
[ -e "scripts/mirrors" ] || {
  echo 'Could not find mirrors file...'
  echo 'scripts/mirrors is not present'
  exit 1
}
[ -e "scripts/eselect-repo.conf" ] || {
  echo 'Could not find eselect-repo.conf file...'
  echo 'scripts/eselect-repo.conf is not present'
  exit 1
}
[ "$openrc" ] && init="openrc"
: "${init:=systemd}"
tag="20240918T225506Z"
name="stage3-armv7a_hardfp"
suffix="tar.xz"
url="https://distfiles.gentoo.org/releases/arm/autobuilds"
url="${url}/${tag}/${name}-${init}-${tag}.${suffix}"
[ -e "$name-$init-$tag.$suffix" ] || curl -LO -C- --progress-bar "$url"
name="${name}-${init}-${tag}.${suffix}"
mkdir -p /usr/local/tmp/stage4-9999
sudo tar -C /usr/local/tmp/stage4-9999 -xvf "${name}"
for path in sys dev; do
  mount --rbind "/$path" "/usr/local/tmp/stage4-9999/$path"
  mount --make-rslave "/usr/local/tmp/stage4-9999/$path"
done
mount --types proc /proc /usr/local/tmp/stage4-9999/proc
mount --bind /run /usr/local/tmp/stage4-9999/run
mount --make-slave /usr/local/tmp/stage4-9999/run
cp -v /etc/resolv.conf /usr/local/tmp/stage4-9999/etc/resolv.conf

[ ! "$repo" -a ! -d /usr/local/tmp/stage4-9999/var/db/repos/local ] && repo="local"
: "${repo:=nyan}"
git clone https://github.com/Mia-Rain/nyan-repo-gentoo "/usr/local/tmp/stage4-9999/var/db/repos/$repo"
tmproot() {
  chroot /usr/local/tmp/stage4-9999 /usr/bin/bash -c "$@"
}
bail() {
  umount -R /usr/local/tmp/stage4-9999/dev
  umount -R /usr/local/tmp/stage4-9999/run
  umount -R /usr/local/tmp/stage4-9999/proc
  umount -R /usr/local/tmp/stage4-9999/sys
  exit "${1:-0}"
}
tmproot "ping -c1 1.1.1.1 || {
  echo 'network is required to sync repos'
  exit 1
}" || bail 1
echo 'Copying ./scripts ...'
mkdir -p "/usr/local/tmp/stage4-9999/scripts-mia"
cp -arv ./scripts/* /usr/local/tmp/stage4-9999/scripts-mia/
tmproot "emerge-webrsync" || bail 1
tmproot "cat /scripts-mia/mirrors >> /etc/portage/make.conf"
tmproot "yes | emerge --sync --quiet"
tmproot "yes | emerge app-eselect/eselect-repository"
tmproot "mkdir -p /etc/portage/repos.conf"
tmproot "cat /scripts-mia/eselect-repo.conf > /etc/portage/repos.conf/eselect-repo.conf"
tmproot "ln -s /usr/share/portage/config/repos.conf /etc/portage/repos.conf/gentoo.conf"
tmproot "mkdir -p /etc/portage/package.accept_keywords"
tmproot "mkdir -p /etc/portage/package.use"
tmproot "cat /scripts-mia/package.demask.dispatch > /etc/portage/package.accept_keywords/zz-autounmask"
# don't bother naming since --autounmask will write changes to a pre-existing file, making multiple files useless
tmproot "cat /scripts-mia/package.use.dispatch > /etc/portage/package.use/gentoo"
# base console system
# networking, xorg, mesa, etc are still not present
printf '
Minimal console system built in /usr/local/tmp/stage4-9999
'

bail 0
