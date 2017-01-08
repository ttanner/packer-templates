#!/bin/sh

export DEBIAN_FRONTEND=noninteractive
. config.vm

test "$i386" = true || dpkg --remove-architecture i386

sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT=""/' -e "s/GRUB_CMDLINE_LINUX=\"net.ifnames=0 nousb noplymouth\"/GRUB_CMDLINE_LINUX=\"vga=$vga net.ifnames=0 nousb noplymouth\"/"  -e 's/GRUB_TIMEOUT=10/GRUB_TIMEOUT=0/' /etc/default/grub
# high res text
sed -i -e 's/FONTFACE="VGA"/FONTFACE="TerminusBold"/' -e 's/FONTSIZE="8x16"/FONTSIZE="8x14"/' /etc/default/console-setup

rm -rf /lib/modules/*-generic/kernel/ubuntu/vbox

# do not clear the boot console
mkdir /etc/systemd/system/getty@tty1.service.d
echo -e "[Service]\nTTYVTDisallocate=no" > /etc/systemd/system/getty@tty1.service.d/noclear.conf

# disable rev lookups
echo "UseDNS no" >> /etc/ssh/sshd_config

# move cached packages to destination
mv /tmp/aptcache/* /var/cache/apt/archives

# select mirror
if test "$mirror" = auto; then
  mirror="mirror://mirrors.ubuntu.com/mirrors.txt"
  if test -z "$http_proxy" -a "$offline" = false; then
    netselect=/var/cache/apt/archives/netselect_0.3.ds1-28_amd64.deb
    if test ! -f $netselect; then
      wget -O $netselect http://ftp.us.debian.org/debian/pool/main/n/netselect/netselect_0.3.ds1-28_amd64.deb # netselect-apt_0.3.ds1-28_all.deb
    fi
    dpkg -i $netselect
    mirrors=`wget -q -O- https://launchpad.net/ubuntu/+archivemirrors | grep -P -B8 "statusUP|statusSIX" |  grep -o -P "(f|ht)tp.*\"" | tr '"\n' '  '`
    fmirror=`netselect -s1 -t20 $mirrors 2>/dev/null | awk '{print $2;}'`
    test -n "$fmirror" && mirror=$fmirror
  fi
fi
echo "using mirror $mirror"
cat > /etc/apt/sources.list <<EOF
deb $mirror xenial main restricted universe multiverse
# deb-src $mirror xenial main restricted multiverse

deb $mirror xenial-updates main restricted universe multiverse
# deb-src $mirror xenial-updates main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu xenial-security main restricted universe multiverse
# deb-src http://security.ubuntu.com/ubuntu xenial-security main restricted universe multiverse

deb $mirror xenial-backports main restricted universe multiverse
# deb-src $mirror xenial-backports main restricted universe multiverse

# deb http://archive.canonical.com/ubuntu xenial partner
# deb-src http://archive.canonical.com/ubuntu xenial partner
EOF

if test "$offline" = false; then
  # update apt sources
  apt-get update

  # Update to the latest kernel
  apt-get install -y linux-generic linux-image-generic #zerofree

  test "$kupgrade" = true || deb_linux_generic="linux-headers-generic linux-image-generic"

  apt-get purge -y plymouth-theme-ubuntu-text \
   linux-image-4.4.0-31-generic linux-image-extra-4.4.0-31-generic \
   linux-headers-4.4.0-31 linux-headers-4.4.0-31-generic $deb_linux_generic

  test "$x11" = true && apt-get install -y xserver-xorg-core # required for virtualbox x11 install
fi

# Reboot with the new kernel
shutdown -r now
sleep 5
sync
reboot -f # in case it hangs
exit 0
