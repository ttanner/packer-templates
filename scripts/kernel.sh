#!/bin/sh

export DEBIAN_FRONTEND=noninteractive
. config.vm

test "$i386" = true || dpkg --remove-architecture i386

if test "$plymouth" = true; then
  sed -i -e "s/GRUB_CMDLINE_LINUX=\"net.ifnames=0 nousb noplymouth\"/GRUB_CMDLINE_LINUX=\"vga=$vga net.ifnames=0 nousb quiet\"/" \
  /etc/default/grub
else
  sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT=""/' \
  -e "s/GRUB_CMDLINE_LINUX=\"net.ifnames=0 nousb noplymouth\"/GRUB_CMDLINE_LINUX=\"vga=$vga net.ifnames=0 nousb noplymouth\"/" \
  /etc/default/grub
fi
# high res text
sed -i -e 's/FONTFACE="VGA"/FONTFACE="TerminusBold"/' -e 's/FONTSIZE="8x16"/FONTSIZE="8x14"/' /etc/default/console-setup

rm -rf /lib/modules/*-generic/kernel/ubuntu/vbox

# do not clear the boot console
mkdir /etc/systemd/system/getty@tty1.service.d
echo -e "[Service]\nTTYVTDisallocate=no" > /etc/systemd/system/getty@tty1.service.d/noclear.conf

# disable rev lookups
echo "UseDNS no" >> /etc/ssh/sshd_config

#if test "$PACKER_BUILDER_TYPE" = virtualbox-iso; then
#  # add TRIM support for / in virtualbox - CAUSES DISK ERRORS - use fstrim
#  sed -i "s/remount-ro/remount-ro,discard/" /etc/fstab
#fi

# move cached packages to destination
mv /tmp/aptcache/* /var/cache/apt/archives

release=`lsb_release -cs`

# select mirror
if test "$mirror" = auto; then
  mirror="mirror://mirrors.ubuntu.com/mirrors.txt"
  if test -z "$http_proxy" -a "$offline" = false; then
    # get current netselect - version/link may be broken
    nsversion=0.3.ds1-28+b1
    netselect=/var/cache/apt/archives/netselect_${nsversion}_amd64.deb
    if test ! -f $netselect; then
      wget -O $netselect http://http.us.debian.org/debian/pool/main/n/netselect/netselect_${nsversion}_amd64.deb
      # netselect-apt_0.3.ds1-28_all.deb
    fi
    if test -f $netselect; then
      dpkg -i $netselect
      mirrors=`wget --no-check-certificate -q -O- https://launchpad.net/ubuntu/+archivemirrors | grep -P -B8 "statusUP|statusSIX" |  grep -o -P "(f|ht)tp.*\"" | tr '"\n' '  '`
      fmirror=`netselect -s1 -t20 $mirrors 2>/dev/null | awk '{print $2;}'`
      test -n "$fmirror" && mirror=$fmirror
      dpkg --purge netselect
    else
      echo "could not download netselect. falling back to mirror list"
    fi
  fi
fi
echo "using mirror $mirror"
cat > /etc/apt/sources.list <<EOF
deb $mirror $release main restricted universe multiverse
# deb-src $mirror $release main restricted multiverse

deb $mirror $release-updates main restricted universe multiverse
# deb-src $mirror $release-updates main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu $release-security main restricted universe multiverse
# deb-src http://security.ubuntu.com/ubuntu $release-security main restricted universe multiverse

deb $mirror $release-backports main restricted universe multiverse
# deb-src $mirror $release-backports main restricted universe multiverse

# deb http://archive.canonical.com/ubuntu $release partner
# deb-src http://archive.canonical.com/ubuntu $release partner
EOF

test "$release" != "xenial" && echo "deb $mirror xenial main restricted universe multiverse" >> /etc/apt/sources.list

if test "$offline" = false; then
  # update apt sources
  apt-get update

  # Update to the latest kernel and definitely delete the original kernel.
  # Use generic packages as we don't know the current version.
  stack=
  test "$hwe" = true && stack=-hwe-16.04
  if test "$PACKER_BUILDER_TYPE" = virtualbox-iso; then
    extra_install=linux-headers-generic$stack # need to build kernel modules
    if test "$x11" = true; then
      extra_install="$extra_install xserver-xorg-core$stack" # required before virtualbox x11 install
    fi
  fi
  apt-get install -y linux-image-virtual$stack $extra_install #zerofree

  if test "$kupgrade" = false -o "$hwe" = true; then
    kernel_purge="linux-headers-generic linux-image-virtual"
  fi
  if test "$kupgrade" = false -a "$hwe" = true; then
    kernel_purge="$kernel_purge linux-image-virtual$stack"
  fi
  # remove original kernel
  original=
  if test "$release" = "xenial"; then
    original=4.4.0-62
  elif test "$release" = "yakkety"; then
    original=4.8.0-22
  elif test "$release" = "zesty"; then
    original=4.10.0-19
  fi
  apt-get purge -y $kernel_purge linux-image-$original-generic linux-headers-$original
fi

sync
echo Reboot with the new kernel
service ssh stop # prevent a new login by packer
ifdown eth0
shutdown -r now
exit 0
