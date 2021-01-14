#!/bin/bash
set -e
if [ -d chroot ] ; then
    umount -lf -R chroot/* 2>/dev/null || true
    rm -rf chroot
fi
debootstrap --arch=amd64 --no-merged-usr --extractor=ar sid chroot
for i in dev sys proc run ; do
    mount --bind /$i chroot/$i
done
chroot chroot apt-get update
curl https://liquorix.net/add-liquorix-repo.sh | chroot chroot bash
chroot chroot apt-get install linux-image-liquorix-amd64 grub-pc-bin grub-efi live-config live-boot -y
chroot chroot apt clean
for i in usr/share/locale usr/share/man sbin/init
do 
  rm -rf chroot/$i
done
install init chroot/sbin/init

mkdir debian || true
umount -lf -R chroot/* 2>/dev/null || true
mksquashfs chroot filesystem.squashfs -comp gzip -wildcards
mkdir -p debian/live
mv filesystem.squashfs debian/live/filesystem.squashfs

cp -pf chroot/boot/initrd.img-* debian/live/initrd.img
cp -pf chroot/boot/vmlinuz-* debian/live/vmlinuz

mkdir -p debian/boot/grub/
echo 'menuentry "Start debian GNU/Linux 64-bit" --class debian {' > debian/boot/grub/grub.cfg
echo '    linux /live/vmlinuz boot=live live-config live-media-path=/live quiet splash --' >> debian/boot/grub/grub.cfg
echo '    initrd /live/initrd.img' >> debian/boot/grub/grub.cfg
echo '}' >> debian/boot/grub/grub.cfg

grub-mkrescue debian -o debian-gnulinux-$(date +%s).iso
