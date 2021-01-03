## Setting Up Manjaro Or Archlinux
### CLI Configuration
We start by using our package manager `pacman` to get all necessary binaries. We'll be omitting `python` and `node` here as `python` will come with every distro and `node` will be managed by it's own version manager.
```
pacman -S diff-so-fancy htop lsd bat fd ripgrep git vim zsh tmux
```
Now we install `n` for managing node instead of using pacman
```
curl -L https://git.io/n-install | bash
```
Now we update our python node package managers
```
pip3 install --upgrade pip
npm install -g npm npm-check-updates
```
Now for installing tmux package manager
```
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```
After doing so, we can copy `.tmux.conf` to the home directory.
```
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/.tmux.conf -o ~/.tmux.conf
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/.tmux.defaultLayout.conf -o ~/.tmux.defaultLayout.conf
```
Now for installing vim package manager
```
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```
Now that Vundler is installed, we can copy the `.vimrc` to the home directory and install plugins.
```
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/.vimrc -o ~/.vimrc
vim +PluginInstall +qall
```
Now for configuring the shell.
```
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```
Lets ensure that zsh will have fish-like syntax highlighting & autocompletion
```
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```
Download the personal theme to use with oh-my-zsh
```
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/pragmata.zsh-theme -o ~/.oh-my-zsh/themes/pragmata.zsh-theme
```
Now finally set up your zsh run commands file with the better one here.
```
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/.zshrc -o ~/.zshrc
```
To have the theme available in the current terminal, source it up.
```
source ~/.zshrc
```
### Arch From Scratch
When all else fails, the best installation guide is [the official arch wiki](https://wiki.archlinux.org/index.php/installation_guide).

```
# to start, lets ennsure the internet is connected and sync time
ping -c 3 google.com
timedatectl set-ntp true

# Use this to make sure you know your drive names, mine show `nvme0n1` and `nvme1n1`. I'll reference those going forward to stripe (RAID 0) those m.2 drives.
fdisk -l

# Will be using GPT and partition 2 nvme drives based on their sizes. Your sizes may be different.
cfdisk /dev/nvme0n1
# create 500M
# create 16G
# create 900G
# create 15G
# write and then quit
cfdisk /dev/nvme1n1
# create 16G
# create 900G
# create 15G
# write and then quit
fdisk -l

# now that the drives are partitioned lets setup raid 0
mdadm --create --verbose --level=0 --metadata=1.2 --chunk=128 --raid-devices=2 /dev/md0 /dev/nvme0n1p2 /dev/nvme1n1p1
mdadm --create --verbose --level=0 --metadata=1.2 --chunk=128 --raid-devices=2 /dev/md1 /dev/nvme0n1p3 /dev/nvme1n1p2
mdadm --create --verbose --level=0 --metadata=1.2 --chunk=128 --raid-devices=2 /dev/md2 /dev/nvme0n1p4 /dev/nvme1n1p3

# if last one fails for "cannot assemble multi-zone RAID0 with default_layout.. do this last line, and retry otherwise skip
echo 1 > /sys/module/raid0/parameters/default_layout

# Now lets validate those changes
lvmdiskscan

# physical volumes
pvcreate /dev/md0
pvcreate /dev/md1
pvcreate /dev/md2

# volume groups
vgcreate vg_swap /dev/md0
vgcreate vg_main /dev/md1
vgcreate vg_tmp /dev/md2
vgscan

# logical volumes
lvcreate -l +100%FREE vg_swap -n swap
lvcreate -L 60GiB vg_main -n rootfs
lvcreate -l +100%FREE vg_main -n homefs
lvcreate -l +100%FREE vg_tmp -n tmpfs
lvscan

# setup swap, ensure fat32 boot partition & declare ext4 elsewhere
mkswap /dev/mapper/vg_swap-swap
mkfs.ext4 /dev/mapper/vg_main-rootfs
mkfs.ext4 /dev/mapper/vg_main-homefs
mkfs.ext4 /dev/mapper/vg_tmp-tmpfs
swapon /dev/mapper/vg_swap-swap
mkfs.fat -F32 /dev/nvme0n1p1

# now mount points
mount /dev/mapper/vg_main-rootfs /mnt
mkdir /mnt/home
mkdir /mnt/tmp
mount /dev/mapper/vg_main-homefs /mnt/home
mount /dev/mapper/vg_tmp-tmpfs /mnt/tmp
pacstrap -i /mnt base base-devel linux linux-firmware lvm2 mdadm vim
genfstab -U -p  /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash

# Now uncomment "[en_US.UTF-8 UTF-8]"
vim /etc/locale.gen
# it's :wq in-case you've been using emacs too long haha

# Now configure local time
locale-gen
ln -sf /usr/share/zoneinfo/America/Chicago  /etc/localtime
hwclock --systohc --utc

# Now add `dm_mod` between the `()` on `MODULES` and add `mdadm_udev lvm2` between block & filesystems of `HOOKS=()` here:
vim /etc/mkinitcpio.conf

# Now setup grub:
mkinitcpio -p linux
pacman -S grub efibootmgr
mkdir /boot/efi
mount /dev/nvme0n1p1 /boot/efi
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg
mkdir /boot/efi/EFI/BOOT
cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI

# Now you'll add the following within `vim /boot/efi/startup.nsh`:
bcf boot add 1 fs0:\EFI\GRUB\grubx64.efi "My GRUB bootloader"

# Now properly setup networking, substitute `FROSTY` for your computer name.
pacman -S networkmanager
systemctl enable NetworkManager
echo FROSTYARCH > /etc/hostname

# Now add the following within `vim /etc/hosts`:
127.0.0.1 localhost
::1       localhost
127.0.1.1 FROSTYARCH.localdomain FROSTYARCH

# Now setup password
passwd

# Now lets wrap things up. after rebooting, boot to bios, ensure nvme raid is on and remove boot flash drive.
exit
umount -R /mnt
reboot

# Now after boot, login with `root` with the configured password and unncomment `multilib` within:
vim /etc/pacman.conf

# Now lets update everything:
pacman -Syyu

# The following is outdated, but sets up a window manager to get started, substitute `nate` for your name:
pacman -S xorg xorg-server xorg-xinit xterm
useradd -m -g users -G wheel -s /bin/bash nate
EDITOR=vim
uncomment %wheel ALL=(ALL) ALL ctrl o {enter} ctrl x # <-- obv do this in vim not nano
passwd nate
exit
login: nate
sudo pacman -S konsole dolphin firefox kate
```
