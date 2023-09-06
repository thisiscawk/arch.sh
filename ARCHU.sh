#!/bin/bash
loadkeys sv-latin1
cfdisk -z /dev/vda #nvme0n1
mkfs.vfat -F32 /dev/vda1 #nvme0n1p1
fatlabel /dev/vda1 BOOT
mkswap -L SWAP /dev/vda2 #nvme0n1p2
swapon /dev/vda2
mkfs.ext4 -L ROOT /dev/vda3 #nvme0n1p3
mount /dev/vda3 /mnt
mkdir -p /mnt/boot
mkdir -p /mnt/boot/efi
mount /dev/vda1 /mnt/boot/efi
pacstrap -K /mnt base linux linux-firmware base-devel 
genfstab -U /mnt >> /mnt/etc/fstab
cat > archup2.sh <<EOF
#!/bin/bash
ln -sf /usr/share/zoneinfo/Europe/Tallinn /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
locale-gen
pacman -S grub os-prober efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
echo "Enter new root password:"
passwd
echo "anonski" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
pacman -S dhcpcd
echo "KEYMAP=sv-latin1" >> /etc/vconsole.conf
mkinitcpio -P
useradd -m anonski
usermod -aG video,audio,input,power,storage,optical,lp,scanner,dbus,uucp anonski
echo "Enter Password for new user:"
passwd anonski
echo "[lib32]" >> /etc/pacman.conf
echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
pacman -Syyu
pacman -S vim wget curl git btop neofetch openssh dhcpcd 
echo "Port 22" >> /etc/ssh/sshd_config
echo "AddressFamily inet" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "anonski	ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
echo "root	ALL=(ALL) ALL" > /etc/sudoers
sync
exit
EOF
chmod +x archup2.sh
cp ~/archup2.sh /mnt/root/
sync
arch-chroot /mnt/root sh ~/archup2.sh
umount -R /mnt
reboot
