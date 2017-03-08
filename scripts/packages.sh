#!/bin/sh -e

export DEBIAN_FRONTEND=noninteractive
. config.vm

test "$kupgrade" = true || deb_kernel="linux-generic linux-headers-$(uname -r) linux-image-extra-$(uname -r)"
test "$x11" = true || deb_x11="libdrm2 libelf1 libxau6 libx11-6 libx11-data libxcb1 libxdmcp6 libxext6 libxmuu1 xauth"
test "$PACKER_BUILDER_TYPE" = virtualbox-iso -a "$kupgrade" = false && deb_dkms="binutils cpp cpp-5 dkms gcc gcc-5 libasan2 make patch
  libatomic1 libcc1-0 libcilkrts5 libgcc-5-dev libgomp1 libisl15 libitm1 liblsan0 libmpc3 libmpfr4 libmpx0
  libquadmath0 libtsan0 libubsan0"
purge="accountsservice apparmor crda dmidecode dosfstools friendly-recovery
  fuse hdparm installation-report iw language-selector-common libaccountsservice0
  libapparmor-perl libatm1 libfribidi0 libnl-3-200 libnl-genl-3-200
  libpcap0.8 libplymouth4 libpolkit-gobject-1-0 libusb-1.0-0
  libparted2 libpci3 lshw lsof ltrace mlocate netcat-openbsd ntfs-3g
  parted pciutils plymouth popularity-contest powermgmt-base python3-distupgrade
  python3-update-manager sgml-base shared-mime-info strace tasksel tasksel-data tcpdump
  ubuntu-release-upgrader-core update-manager-core usbutils wireless-regdb xml-core
  ubuntu-standard ubuntu-minimal linux-firmware"

apt-get purge -y $purge $deb_kernel $deb_x11 $deb_dkms

if test "$offline" = true; then
  apt-get autoremove -y
  touch /tmp/aptcache.tar
  exit 0
fi

# upgrade all packages
apt-get upgrade -y
apt-get install -y software-properties-common # for add-apt-repository

if test "$llvm" = true; then
  echo "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial main" > /etc/apt/sources.list.d/llvm.list
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

# pack package cache
cd /var/cache/apt/archives/
if test -f nodownload; then
  touch /tmp/aptcache.tar
else
  tar cf /tmp/aptcache.tar *.deb
fi
exit 0
