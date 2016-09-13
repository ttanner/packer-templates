#!/bin/sh -x

export DEBIAN_FRONTEND=noninteractive
source config.vm

test -n "$kupgrade" || deb_kernel="linux-generic linux-headers-$(uname -r) linux-image-extra-$(uname -r)"
test "$PACKER_BUILDER_TYPE" = virtualbox-iso && deb_dkms="binutils cpp cpp-5 dkms gcc gcc-5 libasan2 make patch
  libatomic1 libcc1-0 libcilkrts5 libgcc-5-dev libgomp1 libisl15 libitm1 liblsan0 libmpc3 libmpfr4 libmpx0
  libquadmath0 libtsan0 libubsan0"
purge="accountsservice apparmor crda dmidecode dosfstools friendly-recovery
  fuse gir1.2-glib-2.0 hdparm installation-report isc-dhcp-client iw language-selector-common libaccountsservice0
  libapparmor-perl libatm1 libdrm2 libelf1 libfribidi0 libnl-3-200 libnl-genl-3-200
  libdbus-glib-1-2 libgirepository-1.0-1 libpcap0.8 libplymouth4 libpolkit-gobject-1-0 libusb-1.0-0 libxau6
  libparted2 libpci3 libx11-6 libx11-data libxcb1 libxdmcp6 libxext6
  libxmuu1 lshw lsof ltrace mlocate netcat-openbsd ntfs-3g
  parted pciutils plymouth popularity-contest powermgmt-base python3-dbus python3-distupgrade python3-gi
  python3-update-manager sgml-base shared-mime-info strace tasksel tasksel-data tcpdump
  ubuntu-release-upgrader-core update-manager-core usbutils wireless-regdb xauth xml-core
  ubuntu-standard ubuntu-minimal linux-firmware"

apt-get purge -y $purge $deb_kernel $deb_dkms

# upgrade all packages
apt-get upgrade -y

test "$ansible" = true && extra_pkgs="$extra_pkgs ansible"
if test "$salt" = true; then
  add-apt-repository ppa:saltstack/salt
  extra_pkgs="$extra_pkgs salt-stack"
fi
test "$chef" = true && extra_pkgs="$extra_pkgs chef"
test "$puppet" = true && extra_pkgs="$extra_pkgs puppet"
test "$docker" = true && extra="$extra_pkgs docker"
test -n "$extra_pkgs" && apt-get install -y $extra_pkgs
test -n "$purge_pkgs" && apt-get purge -y $purge_pkgs
apt-get autoremove -y #linux-headers-4.4.0-36

# pack package cache
cd /var/cache/apt/archives/
if test -f nodownload; then
  touch /tmp/aptcache.tar
else
  tar cf /tmp/aptcache.tar *.deb
fi

