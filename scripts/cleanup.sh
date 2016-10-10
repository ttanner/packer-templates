#!/bin/sh -e

apt-get clean
rm -f /tmp/aptcache.tar

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm -f /var/lib/dhcp/*

if test "$PACKER_BUILDER_TYPE" = virtualbox-iso; then
  fstrim -v /
else
  # Zero out the free space to save space in the final image:
  echo "Zeroing device to make space..."
  dd if=/dev/zero of=/EMPTY bs=4M
  rm -f /EMPTY
  sync
  # mount -o ro,remount /
  # zerofree -v /dev/sda1
fi
exit 0

