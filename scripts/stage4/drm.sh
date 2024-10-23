#!/bin/sh
bail() {
  umount -R /usr/local/tmp/stage4-9999/dev
  umount -R /usr/local/tmp/stage4-9999/run
  umount -R /usr/local/tmp/stage4-9999/proc
  umount -R /usr/local/tmp/stage4-9999/sys
  exit "${1:-0}"
}
[ -d /usr/local/tmp/stage4-9999 ] || {
  printf 'Minimum stage missing from /usr/local/tmp/stage4-9999...\n'
  bail 1
  exit 1
}
tmproot() {
  chroot /usr/local/tmp/stage4-9999 /usr/bin/bash -c "$@"
}
for path in sys dev; do
  mount --rbind "/$path" "/usr/local/tmp/stage4-9999/$path"
  mount --make-rslave "/usr/local/tmp/stage4-9999/$path"
done
mount --types proc /proc /usr/local/tmp/stage4-9999/proc
mount --bind /run /usr/local/tmp/stage4-9999/run
mount --make-slave /usr/local/tmp/stage4-9999/run
tmproot "emerge llvm::local llvm-common::local llvmgold::local || exit 1" || bail 1
tmproot "ln -sf /usr/share/llvm/13/bin/llvm-config /usr/bin/ || exit 1" || bail 1
tmproot "emerge --update --deep --changed-use @world || exit 1" || bail 1
tmproot "emerge --unmerge --depclean mesa::gentoo libdrm::gentoo || exit 1" || bail 1
tmproot "emerge mesa::local libdrm::local || exit 1" || bail 1
tmproot "emerge xorg-server::local xorg-drivers::local xf86-video-nouveau::local || exit 1" || bail 1
