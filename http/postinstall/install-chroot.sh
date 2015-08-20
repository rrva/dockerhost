DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
echo vagrant > /etc/hostname
echo "127.0.0.1 vagrant" >> /etc/hosts
apt-get update -y
apt-get upgrade -y
apt-get install -y linux-image-virtual linux-headers-virtual openssh-server sudo adduser vim less grub-pc apt-transport-https lsb-release net-tools
sed -i -e 's#GRUB_CMDLINE_LINUX=""#GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"#g' /etc/default/grub
sed -i 's/\(^GRUB_HIDDEN_TIMEOUT.*$\)/#\1/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install /dev/sda
adduser vagrant --disabled-password --gecos ""
echo -e "vagrant:vagrant" | chpasswd
echo -e "Defaults:vagrant  !requiretty\nvagrant ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
systemctl enable systemd-networkd.service
systemctl disable display-manager.service
grep -q "^UseDNS " /etc/ssh/sshd_config && sed "s/^UseDNS .*/UseDNS no/" -i /etc/ssh/sshd_config || sed "$ a\UseDNS no" -i /etc/ssh/sshd_config
echo -e "/dev/sda4               /               btrfs            rw,compress=lzo,autodefrag,noatime,discard,space_cache        0 1\n/dev/sda3               /boot           ext4            rw,relatime,data=ordered        0 2" >> /etc/fstab
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
Name=en*

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
apt-get -y autoremove --purge
apt-get -y autoclean
apt-get -y clean
find /var/cache -type f -delete
find /var/lib/apt -type f -delete
