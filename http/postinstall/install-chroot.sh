#!/usr/bin/env bash
echo install-chroot starting
DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH
cat << EOF > /usr/sbin/policy-rc.d
#!/bin/sh
exit 101
EOF
chmod 755 /usr/sbin/policy-rc.d
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
echo vagrant > /etc/hostname
echo "127.0.0.1 vagrant" >> /etc/hosts
echo "deb http://archive.ubuntu.com/ubuntu/ wily universe" >> /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu/ wily-updates universe" >> /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu/ wily-security universe" >> /etc/apt/sources.list
apt-get update -y || apt-get update -y
apt-get upgrade -y
apt-get install -y linux-image-generic openssh-server sudo adduser vim-tiny less grub-pc apt-transport-https lsb-release net-tools zram-config btrfs-tools nfs-common portmap fuse lxd lxd-client iputils-ping curl cachefilesd
sed -i -e 's#GRUB_TIMEOUT=10#GRUB_TIMEOUT=0#g' /etc/default/grub
sed -i -e 's#GRUB_CMDLINE_LINUX=""#GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"#g' /etc/default/grub
sed -i 's/\(^GRUB_HIDDEN_TIMEOUT.*$\)/#\1/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install /dev/sda
adduser vagrant --disabled-password --gecos ""
echo -e "vagrant:vagrant" | chpasswd
echo -e "root:vagrant" | chpasswd
echo -e "Defaults:vagrant  !requiretty\nvagrant ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
systemctl enable systemd-networkd.service
systemctl disable display-manager.service
grep -q "^UseDNS " /etc/ssh/sshd_config && sed "s/^UseDNS .*/UseDNS no/" -i /etc/ssh/sshd_config || sed "$ a\UseDNS no" -i /etc/ssh/sshd_config
echo -e "/dev/sda4               /               btrfs            rw,compress=lzo,autodefrag,noatime,ssd,discard,space_cache        0 1\n/dev/sda3               /boot           ext4            rw,relatime,data=ordered        0 2" >> /etc/fstab
cd ~vagrant
mkdir .ssh
wget https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -O .ssh/authorized_keys
chmod 700 .ssh
chmod 600 .ssh/authorized_keys
chown -R vagrant:vagrant .ssh
echo "deb https://apt.dockerproject.org/repo ubuntu-wily main" > /etc/apt/sources.list.d/docker.list
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
apt-get update -y
apt-get install -y docker-engine
cat << EOF > /etc/systemd/network/dhcp.network
[Match]
Name=en* eth*

[Network]
DHCP=yes
EOF
cat << EOF > /etc/systemd/system/docker-tcp.socket
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=2375
BindIPv6Only=both
Service=docker.service

[Install]
WantedBy=sockets.target
EOF
systemctl enable docker.service
systemctl enable docker-tcp.socket
adduser vagrant docker
adduser vagrant lxd
apt-get -y clean
chmod 755 /install-vmtool.sh
/install-vmtool.sh
apt-get upgrade -y
apt-get remove -y gcc-5 cpp-5 libgcc-5-dev thermald linux-firmware
apt-get -y autoremove --purge
apt-get -y autoclean
apt-get -y clean
find /var/cache -type f -delete
find /var/lib/apt -type f -delete
systemctl enable systemd-resolved
rm /etc/resolv.conf
ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
rm /usr/sbin/policy-rc.d
