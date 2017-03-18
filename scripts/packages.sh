#!/bin/sh -e

export DEBIAN_FRONTEND=noninteractive
. config.vm
. /etc/profile.d/proxy.sh

purge="accountsservice apparmor crda dmidecode dosfstools friendly-recovery
  fuse hdparm installation-report iw language-selector-common libaccountsservice0
  libapparmor-perl libatm1 libfribidi0 libnl-3-200 libnl-genl-3-200
  libpcap0.8 libpolkit-gobject-1-0 libusb-1.0-0
  libparted2 libpci3 lshw lsof ltrace mlocate netcat-openbsd ntfs-3g
  parted pciutils popularity-contest powermgmt-base
  sgml-base shared-mime-info strace tasksel tasksel-data tcpdump
  usbutils wireless-regdb xml-core
  ubuntu-standard ubuntu-minimal linux-firmware"
if test "$kupgrade" = false; then
  purge="$purge linux-generic linux-headers-$(uname -r) linux-image-extra-$(uname -r)
  python3-distupgrade python3-update-manager ubuntu-release-upgrader-core update-manager-core"
fi
if test "$x11" = false; then
  purge="$purge libelf1 libxau6 libx11-6 libx11-data libxcb1 libxdmcp6 libxext6 libxmuu1 xauth"
fi
if test "$PACKER_BUILDER_TYPE" = virtualbox-iso -a "$kupgrade" = false; then
  purge="$purge binutils cpp cpp-5 dkms gcc gcc-5 libasan2 make patch
  libatomic1 libcc1-0 libcilkrts5 libgcc-5-dev libgomp1 libisl15 libitm1 liblsan0 libmpc3 libmpfr4 libmpx0
  libquadmath0 libtsan0 libubsan0"
fi

test "$plymouth" = true || purge="$purge libdrm2 libplymouth4 plymouth"

apt-get purge -y $purge

if test "$offline" = true; then
  apt-get autoremove -y
  touch /tmp/aptcache.tar
  exit 0
fi

# upgrade all packages
apt-get upgrade -y
apt-get install -y software-properties-common # for add-apt-repository

if test "$plymouth" = true; then
  extra_pkgs="$extra_pkgs plymouth-theme-ubuntu-mate-logo plymouth-theme-ubuntu-mate-text"
fi
if test "$mate" = true; then
  extra_pkgs="$extra_pkgs apturl avahi-utils caja-gksu caja-open-terminal caja-sendto
  gnome-settings-daemon-schemas gnome-system-tools gsettings-ubuntu-schemas
  indicator-application-gtk2 language-selector-gnome lightdm mate-applet-topmenu mate-applets
  mate-desktop-environment-core mate-gnome-main-menu-applet
  mate-indicator-applet mate-media mate-menu mate-netspeed
  mate-sensors-applet-common mate-system-monitor mate-themes mate-tweak
  mate-utils pinentry-gtk2 pluma
  session-migration sessioninstaller topmenu-gtk2 topmenu-gtk3
  xdg-user-dirs-gtk xorg-hwe-16.04 zip
  fonts-freefont-ttf fonts-liberation ttf-dejavu
  dmz-cursor-theme mate-media mate-themes ubuntu-mate-artwork ubuntu-mate-lightdm-theme"
fi
if test "$llvm" = true; then
  echo "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-4.0 main" > /etc/apt/sources.list.d/llvm.list
  wget -O - http://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
  needupdate=true
  extra_pkgs="$extra_pkgs clang-4.0"
fi
if test "$salt" = true; then
  echo "deb https://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest xenial main" > /etc/apt/sources.list.d/saltstack.list
  wget -O - https://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest/SALTSTACK-GPG-KEY.pub | apt-key add -
  needupdate=true
  extra_pkgs="$extra_pkgs salt-minion salt-ssh"
fi
if test "$qt" = true; then
  ppas="$ppas ppa:beineri/opt-qt58-xenial"
  extra_pkgs="$extra_pkgs qt58base"
fi
for ppa in $ppas; do
  add-apt-repository -y $ppa
  needupdate=true
done
test "$needupdate" = true && apt-get update
test -n "$extra_pkgs" && apt-get install -y $extra_pkgs
test -n "$purge_pkgs" && apt-get purge -y $purge_pkgs
apt-get autoremove -y #linux-headers-4.4.0-62

if test "$mate" = true; then
  cat > /etc/lightdm/lightdm.conf.d/autologin.conf <<EOF
[Seat:*]
autologin-guest=false
autologin-user=$SUDO_USER
autologin-user-timeout=0
EOF
fi

# pack package cache
cd /var/cache/apt/archives/
if test -f nodownload; then
  touch /tmp/aptcache.tar
else
  tar cf /tmp/aptcache.tar *.deb
fi
exit 0
