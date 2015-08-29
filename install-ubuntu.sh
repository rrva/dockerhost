HTTP=$(sed 's|.*url=\([^ ]*/\).*|\1postinstall|' /proc/cmdline)
echo HTTP is "$HTTP"
sgdisk -og /dev/sda
sgdisk -n 1:2048:4095 -c 1:"BIOS Boot Partition" -t 1:ef02 /dev/sda
sgdisk -n 2:4096:413695 -c 2:"EFI System Partition" -t 2:ef00 /dev/sda
sgdisk -n 3:413696:823295 -c 3:"Linux /boot" -t 3:8300 /dev/sda
ENDSECTOR=`sgdisk -E $1`
sgdisk -n 4:823296:$ENDSECTOR -c 4:"Linux root" -t 4:8300 /dev/sda
modprobe brd rd_nr=1 max_part=0 rd_size=2097152
mkfs.ext4 /dev/sda3
mkfs.btrfs /dev/ram0
mkdir /chroot
mount -o compress=zlib /dev/ram0 /chroot
mkdir /chroot/boot
mount /dev/sda3 /chroot/boot
#curl -s http://cdimage.ubuntu.com/ubuntu-core/daily/current/wily-core-amd64.tar.gz | tar -C /chroot -xzpf -
curl -o /wily.tar.gz -s ${HTTP}/wily-core-amd64.tar.gz
echo Unpacking wily core
tar -C /chroot -xzpf /wily.tar.gz
echo Done unpacking
if [ -e /.vbox_version ]; then
  VBOX_VERSION=$(cat /.vbox_version)
  mount -o loop /VBoxGuestAdditions_$VBOX_VERSION.iso /chroot/mnt
fi
cp /etc/resolv.conf /chroot/etc/resolv.conf
curl -s -o /chroot/install-chroot.sh "${HTTP}/install-chroot.sh"
curl -s -o /chroot/install-vmtool.sh "${HTTP}/install-vmtool.sh"
mkdir /chroot/fake
curl -s -o /chroot/fake/uname "${HTTP}/fake-uname"
chmod 755 /chroot/fake/uname
for f in /sys /proc /dev ; do mount --rbind $f /chroot/$f ; done
chroot /chroot /bin/bash install-chroot.sh
mkdir /final
mkfs.btrfs -m single -L root /dev/sda4
mount -o compress=zlib /dev/sda4 /final
rm /chroot/install-chroot.sh
cp -ax /chroot/. /final
umount /chroot/boot
mount /dev/sda3 /final/boot
for f in /sys /proc /dev ; do mount --rbind $f /final/$f ; done
curl -s -o /final/install-grub.sh "${HTTP}/install-grub.sh"
chroot /final /bin/bash install-grub.sh
rm /final/install-grub.sh
echo Done installing
