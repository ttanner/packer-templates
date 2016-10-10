#!/bin/sh -e

export DEBIAN_FRONTEND=noninteractive
# Install open-vm-tools so we can mount shared folders
apt-get install -y open-vm-tools
test "$x11" = true && apt-get install -y xserver-xorg-input-vmmouse xserver-xorg-video-vmware

# Add /mnt/hgfs so the mount works automatically with Vagrant
mkdir /mnt/hgfs
exit 0
