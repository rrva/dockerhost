HTTP=$(sed 's|.*url=\([^ ]*/\).*|\1postinstall|' /proc/cmdline)
echo HTTP is "$HTTP"
sgdisk -og /dev/sda
sgdisk -n 1:2048:4095 -c 1:"BIOS Boot Partition" -t 1:ef02 /dev/sda
sgdisk -n 2:4096:413695 -c 2:"EFI System Partition" -t 2:ef00 /dev/sda
sgdisk -n 3:413696:823295 -c 3:"Linux /boot" -t 3:8300 /dev/sda
ENDSECTOR=`sgdisk -E $1`
sgdisk -n 4:823296:$ENDSECTOR -c 4:"Linux root" -t 4:8300 /dev/sda
modprobe brd rd_nr=1 max_part=0 rd_size=$((2*1024*1024))
mkfs.ext4 /dev/sda3
mkfs.btrfs /dev/ram0
mkdir /chroot
mount -o compress=zlib /dev/ram0 /chroot
mkdir /chroot/boot
mount /dev/sda3 /chroot/boot
curl -s http://cdimage.ubuntu.com/ubuntu-core/daily/current/wily-core-amd64.tar.gz | tar -C /chroot -xvzpf -
cp /etc/resolv.conf /chroot/etc/resolv.conf
curl -s -o /chroot/install-chroot.sh "${HTTP}/install-chroot.sh"
for f in /sys /proc /dev ; do mount --rbind $f /chroot/$f ; done
chroot /chroot /bin/bash install-chroot.sh
mkdir /final
mkfs.btrfs /dev/sda4
mount -o compress=zlib /dev/sda4 /final
cp -ax /chroot/. /final
echo Done installing
