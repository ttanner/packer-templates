#!/bin/sh -e

source /etc/profile.d/proxy.sh
# Set up sudo
echo "%vagrant ALL=NOPASSWD:ALL" > /etc/sudoers.d/vagrant
chmod 0440 /etc/sudoers.d/vagrant

# Setup sudo to allow no-password sudo for "sudo"
usermod -a -G sudo $SUDO_USER

# Installing vagrant keys
mkdir ~/.ssh
chmod 700 ~/.ssh
cd ~/.ssh
url=https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
data_url=http://$PACKER_HTTP_ADDR
if wget --spider $data_url/authorized_keys 2>/dev/null; then
  url=$data_url/authorized_keys
fi
wget --no-check-certificate -Oauthorized_keys $url
chmod 600 ~/.ssh/authorized_keys
chown -R $SUDO_USER ~/.ssh
exit 0
