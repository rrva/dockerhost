#!/usr/bin/env bash
echo install-grub starting
DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH
sed -i -e 's#GRUB_TIMEOUT=10#GRUB_TIMEOUT=0#g' /etc/default/grub
sed -i -e 's#GRUB_CMDLINE_LINUX=""#GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1 elevator=noop"#g' /etc/default/grub
sed -i 's/\(^GRUB_HIDDEN_TIMEOUT.*$\)/#\1/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install /dev/sda
