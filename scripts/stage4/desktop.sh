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
printf 'Please select your desktop; enter mate, xfce4, or icewm\n'
printf 'lightdm is provided as the display manager\n'
read -r desktop
case "$desktop" in
  xfce*) tmproot "emerge xfce-base/xfce4-meta || exit 1" || bail 1 ;;
  mate) tmproot "emerge mate-base/mate || exit 1" || bail 1 ;;
  icewm) tmproot "emerge x11-wm/icewm || exit 1" || bail 1 ;;
esac
tmproot "emerge lightdm x11-misc/lightdm-gtk-greeter || exit 1" || bail 1
[ "$openrc" ] && {
  tmproot "emerge gui-libs/display-manager-init || exit 1" || bail 1
  tmproot 'printf DISPLAYMANAGER="lightdm" > /etc/conf.d/display-manager || exit 1' || :
  tmproot "rc-update add dbus default || exit 1" || :
  tmproot "rc-update add display-manager default || exit 1" || :
} || tmproot "systemctl enable lightdm || bail 1" || :
printf 'media-video/pipewire sound-server pipewire-alsa dbus ffmpeg extra' > /usr/local/tmp/stage4-9999/etc/portage/package.use/gentoo
tmproot "emerge pipewire libpulse || exit 1" || bail 1
[ "$openrc" ] || {
  # there is no standard non-systemd way to start pipewire
  tmproot "systemctl --user disable --now pulseaudio.socket pulseaudio.service || exit 1" || :
  tmproot "systemctl --user enable --now pipewire-pulse.socket wireplumber.service || exit 1" || :
  tmproot "systemctl --user enable --now pipewire.service || exit 1" || :
  # this last one is optional; see gentoo wiki pipewire
}
tmproot "useradd -m -G wheel,audio,video -u 1000 -g 1000 linux"
tmproot "echo 'linux:changeme' | chpasswd"
tmproot "echo 'root:changeme' | chpasswd"
