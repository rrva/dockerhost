HTTP=$(sed 's|.*url=\([^ ]*/\).*|\1postinstall|' /proc/cmdline)
echo HTTP is "$HTTP"
sgdisk -og /dev/sda
sgdisk -n 1:2048:4095 -c 1:"BIOS Boot Partition" -t 1:ef02 /dev/sda
sgdisk -n 2:4096:413695 -c 2:"EFI System Partition" -t 2:ef00 /dev/sda
sgdisk -n 3:413696:823295 -c 3:"Linux /boot" -t 3:8300 /dev/sda
ENDSECTOR=`sgdisk -E $1`
sgdisk -n 4:823296:$ENDSECTOR -c 4:"Linux root" -t 4:8300 /dev/sda
mkfs.ext4 /dev/sda3
mkfs.btrfs /dev/sda4
mount -o compress=lzo,space_cache,discard /dev/sda4 /mnt
cd /mnt
mkdir boot
mount /dev/sda3 /mnt/boot
#curl -s "${HTTP}/wily-core-amd64.tar.gz" | tar xvzpf -
curl -s http://cdimage.ubuntu.com/ubuntu-core/daily/current/wily-core-amd64.tar.gz | tar xvzpf -
cp /etc/resolv.conf /mnt/etc/resolv.conf
curl -s -O "${HTTP}/install-chroot.sh"
for f in /sys /proc /dev ; do mount --rbind $f /mnt/$f ; done
chroot /mnt /bin/bash install-chroot.sh
