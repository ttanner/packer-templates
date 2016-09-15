#!/bin/sh

export DEBIAN_FRONTEND=noninteractive
source config.vm
#apt-get clean

test -n "$http_proxy" && echo "Acquire::http::Proxy \"$http_proxy\";" >> /etc/apt/apt.conf.d/30proxy
test -n "$ftp_proxy" && echo "Acquire::ftp::Proxy \"$ftp_proxy\";" >> /etc/apt/apt.conf.d/30proxy

touch /etc/profile.d/proxy.sh
test -n "$http_proxy" && echo "export http_proxy=\"$http_proxy\"" >> /etc/profile.d/proxy.sh
test -n "$https_proxy" && echo "export https_proxy=\"$https_proxy\"" >> /etc/profile.d/proxy.sh
test -n "$ftp_proxy" && echo "export ftp_proxy=\"$ftp_proxy\"" >> /etc/profile.d/proxy.sh
test -n "$no_proxy" && echo "export no_proxy=\"$no_proxy\"" >> /etc/profile.d/proxy.sh

test "$i386" = true || dpkg --remove-architecture i386

# update apt sources
apt-get update
# move cached packages to destination
mv /tmp/aptcache/* /var/cache/apt/archives

sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT=""/' -e 's/GRUB_TIMEOUT=10/GRUB_TIMEOUT=0/' /etc/default/grub
# high res text
sed -i -e 's/FONTFACE="VGA"/FONTFACE="TerminusBold"/' -e 's/FONTSIZE="8x16"/FONTSIZE="8x14"/' /etc/default/console-setup

# Update to the latest kernel
apt-get install -y linux-generic linux-image-generic #zerofree

rm -rf /lib/modules/*-generic/kernel/ubuntu/vbox

test -n "$kupgrade" || deb_linux_generic="linux-headers-generic linux-image-generic"

apt-get purge -y plymouth-theme-ubuntu-text \
 linux-image-4.4.0-31-generic linux-image-extra-4.4.0-31-generic \
 linux-headers-4.4.0-31 linux-headers-4.4.0-31-generic $deb_linux_generic

# do not clear the boot console
mkdir /etc/systemd/system/getty@tty1.service.d
echo -e "[Service]\nTTYVTDisallocate=no" > /etc/systemd/system/getty@tty1.service.d/noclear.conf

# Reboot with the new kernel
shutdown -r now
sleep 60
