#!/bin/sh -e

export DEBIAN_FRONTEND=noninteractive
. config.vm
. /etc/profile.d/proxy.sh

release=`lsb_release -cs`

purge="installation-report libatm1 libfribidi0 libpci3 libusb-1.0-0 netcat-openbsd
 pciutils tasksel tasksel-data ubuntu-minimal usbutils"

if test "$kupgrade" = false; then
  headers=linux-headers-$(uname -r)
  purge="$purge ${headers%-generic}"
fi
if test "$PACKER_BUILDER_TYPE" = virtualbox-iso -a "$kupgrade" = false; then
  purge="$purge binutils cpp dkms gcc make patch
  libatomic1 libcc1-0 libcilkrts5 libgomp1 libisl15 libitm1 liblsan0 libmpc3 libmpfr4
  libquadmath0 libtsan0 libubsan0"
  if test "$release" = "xenial"; then
    purge="$purge cpp-5 gcc-5 libasan2 libmpx0 libgcc-5-dev "
  elif test "$release" = "yakkety" -o "$release" = "zesty"; then
    purge="$purge cpp-6 gcc-6 libasan3 libmpx2"
  fi
fi

apt-get purge -y $purge

if test "$offline" = true; then
  apt-get autoremove -y
  touch /tmp/aptcache.tar
  exit 0
fi

# upgrade all packages
apt-get upgrade -y

stack=
test "$hwe" = true && stack=-hwe-16.04

extra_pkgs="$extra_pkgs libpam-systemd tmpreaper"
if test "$plymouth" = true; then
  extra_pkgs="$extra_pkgs plymouth-theme-ubuntu-mate-text"
  if test "$x11" = true; then
    extra_pkgs="$extra_pkgs plymouth-theme-ubuntu-mate-logo"
  fi
fi
if test "$x11" = true; then
  extra_pkgs="$extra_pkgs xserver-xorg-core$stack xauth"
fi
if test "$kupgrade" = true; then
  extra_pkgs="$extra_pkgs ubuntu-release-upgrader-core update-manager-core"
fi
if test "$mate" = true; then
  extra_pkgs="$extra_pkgs
  iso-codes info man-db language-selector-common
  apturl avahi-utils caja-gksu caja-open-terminal caja-sendto
  gnome-settings-daemon-schemas gnome-system-tools gsettings-ubuntu-schemas
  indicator-application-gtk2 language-selector-gnome lightdm mate-applet-topmenu mate-applets
  mate-desktop-environment-core mate-indicator-applet mate-media mate-menu
  mate-sensors-applet-common mate-system-monitor mate-themes mate-tweak
  mate-utils pinentry-gtk2 pluma session-migration sessioninstaller topmenu-gtk2 topmenu-gtk3
  xdg-user-dirs-gtk xorg$stack zip fonts-freefont-ttf fonts-liberation ttf-dejavu
  dmz-cursor-theme mate-media mate-themes ubuntu-mate-artwork ubuntu-mate-lightdm-theme"
  test "$release" = "xenial" && extra_pkgs="$extra_pkgs mate-gnome-main-menu-applet"
fi
if test "$llvm" = true; then
  echo "deb http://apt.llvm.org/$release/ llvm-toolchain-$release-4.0 main" > /etc/apt/sources.list.d/llvm.list
  wget -O - http://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
  needupdate=true
  extra_pkgs="$extra_pkgs clang-4.0"
fi
if test "$salt" = true; then
  echo "deb https://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest xenial main" > /etc/apt/sources.list.d/saltstack.list
  wget --no-check-certificate -O - https://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest/SALTSTACK-GPG-KEY.pub | apt-key add -
  needupdate=true
  extra_pkgs="$extra_pkgs salt-minion salt-ssh"
fi
if test "$qt" = true; then
  echo "deb http://ppa.launchpad.net/beineri/opt-qt591-xenial/ubuntu xenial main" > /etc/apt/sources.list.d/qt.list
  apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C65D51784EDC19A871DBDBB710C56D0DE9977759
  #ppas="$ppas ppa:beineri/opt-qt58-xenial"
  extra_pkgs="$extra_pkgs qt59base"
fi
test -n "$ppas" && apt-get install -y software-properties-common # for add-apt-repository
for ppa in $ppas; do
  add-apt-repository -y $ppa
  needupdate=true
done
test "$needupdate" = true && apt-get update
test -n "$extra_pkgs" && apt-get install -y $extra_pkgs
test -n "$purge_pkgs" && apt-get purge -y $purge_pkgs
apt-get autoremove -y

# reduce networking timeout
fname=/etc/systemd/system/network-online.targets.wants/networking.service
test -f $fname && sed -i s/TimeoutStartSec=5min/TimeoutStartSec=30sec/ $fname

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
