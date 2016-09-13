#!/bin/sh -x

export DEBIAN_FRONTEND=noninteractive
# The netboot installs the VirtualBox support (old) so we have to remove it
rmmod vboxvideo vboxguest || true
apt-get install -y dkms

# Install the VirtualBox guest additions
VBOX_VERSION=$(cat .vbox_version)
VBOX_ISO=VBoxGuestAdditions.iso
mount -o loop $VBOX_ISO /mnt
yes|sh /mnt/VBoxLinuxAdditions.run
umount /mnt

#Cleanup VirtualBox
rm $VBOX_ISO

test -n "$kupgrade" || rm -rf /usr/src/vboxguest-*

#shutdown -r now
#sleep 60
