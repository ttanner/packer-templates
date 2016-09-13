#!/bin/sh

export DEBIAN_FRONTEND=noninteractive
source config.vm
#apt-get clean

test -n "$http_proxy" && echo "Acquire::http::Proxy \"$http_proxy\";" >> /etc/apt/apt.conf.d/30proxy
test -n "$ftp_proxy" && echo "Acquire::ftp::Proxy \"$ftp_proxy\";" >> /etc/apt/apt.conf.d/30proxy

test -n "$http_proxy" && echo "export http_proxy=\"$http_proxy\";" >> /etc/profile.d/proxy.sh
test -n "$https_proxy" && echo "export https_proxy=\"$https_proxy\";" >> /etc/profile.d/proxy.sh
test -n "$ftp_proxy" && echo "export ftp_proxy=\"$ftp_proxy\";" >> /etc/profile.d/proxy.sh
test -n "$no_proxy" && echo "export no_proxy=\"$no_proxy\";" >> /etc/profile.d/proxy.sh

# update apt sources
apt-get update
# move cached packages to destination
mv /tmp/aptcache/* /var/cache/apt/archives

sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT="net.ifnames=0 nousb noplymouth"/' -e 's/GRUB_TIMEOUT=10/GRUB_TIMEOUT=0/' /etc/default/grub

# Update to the latest kernel
apt-get install -y linux-generic linux-image-generic 

rm -rf /lib/modules/*-generic/kernel/ubuntu/vbox

test -n "$kupgrade" || deb_linux_generic="linux-headers-generic linux-image-generic"

apt-get purge -y plymouth-theme-ubuntu-text \
 linux-image-4.4.0-31-generic linux-image-extra-4.4.0-31-generic \
 linux-headers-4.4.0-31 linux-headers-4.4.0-31-generic $deb_linux_generic

# Reboot with the new kernel
shutdown -r now
sleep 60
