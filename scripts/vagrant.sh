#!/bin/sh -e

. /etc/profile.d/proxy.sh
# Set up sudo
echo "%vagrant ALL=NOPASSWD:ALL" > /etc/sudoers.d/vagrant
chmod 0440 /etc/sudoers.d/vagrant

# Setup sudo to allow no-password sudo for "sudo"
usermod -a -G sudo $SUDO_USER

# Installing vagrant keys
mkdir ~/.ssh
chmod 700 ~/.ssh
cd ~/.ssh
certfile=/tmp/aptcache/vagrant.pub
if test ! -f $certfile; then
  wget --no-check-certificate -O $certfile https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
fi
cp $certfile authorized_keys
chmod 600 ~/.ssh/authorized_keys
chown -R $SUDO_USER ~/.ssh
exit 0
