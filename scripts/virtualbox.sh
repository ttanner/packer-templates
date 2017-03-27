#!/bin/sh -e

export DEBIAN_FRONTEND=noninteractive
. config.vm
uname -a
# The netboot installs the VirtualBox support (old) so we have to remove it
rmmod vboxvideo vboxguest || true
if test "$offline" = false; then
  apt-get install -y dkms
else
  dpkg -i /var/cache/apt/archives/dkms_2.2.0.3-2ubuntu11.3_all.deb
fi

echo Installing the VirtualBox guest additions
VBOX_VERSION=$(cat .vbox_version)
VBOX_ISO=VBoxGuestAdditions.iso
mount -r -o loop $VBOX_ISO /mnt
yes|sh /mnt/VBoxLinuxAdditions.run
umount /mnt

#Cleanup VirtualBox
rm $VBOX_ISO

test "$kupgrade" = true || rm -rf /usr/src/vboxguest-*

#shutdown -r now
#sleep 60
exit 0
