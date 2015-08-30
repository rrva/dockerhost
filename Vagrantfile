# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  if Vagrant.has_plugin?("vagrant-timezone")
    config.timezone.value = :host
  end
  config.vm.box = "rrva/dockerhost"
  config.vm.provider "virtualbox" do |vb|
     vb.memory = "4096"
     vb.cpus = 4
     vb.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
  end
  config.vm.provider "vmware_fusion" do |vmware|
      vmware.vmx["memsize"] = "8192"
      vmware.vmx["numvcpus"] = "4"
  end
  config.vm.network "private_network", ip: "172.23.0.10", netmask: "255.255.0.0", auto_config: false
  #config.vm.synced_folder "/Users", "/Users", type: "nfs", mount_options:['nolock,vers=3,tcp,noatime,actimeo=1,fsc']

  config.ssh.shell = 'bash'
  config.vm.provision :shell, :inline => <<-HEREDOC
rm /etc/systemd/network/*
cat <<EOF > /etc/systemd/network/br0.network
[Match]
Name=br0

[Network]
DHCP=no
Address=172.23.0.10/16
DNS=172.23.0.1
IPForward=yes
EOF
cat <<EOF > /etc/systemd/network/br0.netdev
[NetDev]
Name=br0
Kind=bridge
EOF
cat <<EOF > /etc/systemd/network/ens32.network
[Match]
Name=ens32 enp0s3 eth0 eno16777728

[Network]
DHCP=yes
IPForward=yes
EOF
cat <<EOF > /etc/systemd/network/ens33.network
[Match]
Name=ens33 enp0s8 eth1 eno33554952

[Network]
Bridge=br0
EOF
mkdir /lib/systemd/system/docker.service.d
cat <<EOF > /lib/systemd/system/docker.service.d/docker.conf
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --dns 172.23.0.10 --bridge=br0 --iptables=false --fixed-cidr=172.23.1.0/24
EOF
cat <<EOF > /etc/systemd/system/iptables-special.service
[Unit]
DefaultDependencies=no
Wants=network-pre.target
Before=network-pre.target

[Service]
Type=oneshot
ExecStart=/etc/lxc/iptables.sh

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF > /etc/lxc/iptables.sh
#!/usr/bin/env bash
iptables -t nat -A POSTROUTING -s 172.16.0.0/12 \! -d 172.16.0.0/12 -j MASQUERADE
iptables -I FORWARD 1 -m physdev --physdev-out ens33 --physdev-is-bridged -p udp --dport 67 --sport 68 -j DROP
iptables -I FORWARD 1 -m physdev --physdev-out enp0s8 --physdev-is-bridged -p udp --dport 67 --sport 68 -j DROP
iptables -I FORWARD 1 -m physdev --physdev-out eth1 --physdev-is-bridged -p udp --dport 67 --sport 68 -j DROP
iptables -I FORWARD 1 -m physdev --physdev-out eno33554952 --physdev-is-bridged -p udp --dport 67 --sport 68 -j DROP
EOF
systemctl enable iptables-special.service
chmod 755 /etc/lxc/iptables.sh
sed -i 's#USE_LXC_BRIDGE="true"#USE_LXC_BRIDGE="false"#g' /etc/default/lxc-net
sed -i 's#lxcbr0#br0#g' /etc/default/lxc-net
sed -i 's#lxcbr0#xxx#g' /etc/dnsmasq.d/lxc
sed -i 's#lxcbr0#br0#g' /etc/lxc/default.conf
lxc profile device remove default eth0
lxc profile device add default eth0 nic parent=br0 nictype=bridged
sudo -H -u vagrant lxc list
systemctl daemon-reload
ifconfig ens33 0.0.0.0
ifconfig enp0s8 0.0.0.0
ifconfig eth1 0.0.0.0
ifconfig eno33554952 0.0.0.0
systemctl restart systemd-networkd
systemctl stop docker
iptables --flush
iptables --flush FORWARD
iptables --flush INPUT
iptables --flush OUTPUT
iptables --table nat --flush
iptables --table nat --delete-chain
iptables --table mangle --flush
iptables --table mangle --delete-chain
iptables --delete-chain
systemctl start iptables-special.service
systemctl restart docker-tcp.socket
systemctl start docker
systemctl restart lxc-net
systemctl restart lxc
systemctl stop lxd
systemctl restart lxd-unix.socket
ifconfig lxcbr0 down
sudo brctl delbr lxcbr0
ifconfig docker0 down
sudo brctl delbr docker0
cat <<EOF > /etc/systemd/system/dnsmasq.service
[Unit]
Description=A lightweight DHCP and caching DNS server
After=network.target
Documentation=man:dnsmasq(8)

[Service]
Type=dbus
BusName=uk.org.thekelleys.dnsmasq
ExecStartPre=/usr/sbin/dnsmasq --test
ExecStart=/usr/sbin/dnsmasq -k --enable-dbus --user=dnsmasq --pid-file
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF > /etc/dnsmasq.conf
interface=br0
dhcp-range=172.23.3.1,172.23.3.255
EOF

systemctl enable dnsmasq.service
systemctl start dnsmasq.service
sudo echo "RUN=yes" > /etc/default/cachefilesd
service cachefilesd start
lxc config set core.trust_password blah
lxc config set core.https_address [::]:8443
systemctl disable lxc lxc-net lxd-unix.socket
echo Provisioning done
HEREDOC
end
