## Setting Up Manjaro Or Archlinux
### CLI Configuration
We start by using our package manager `pacman` to get all necessary binaries. We'll omit `node` as it will be managed by it's own version manager.
- `diff-so-fancy` helps make cli `git diff` look good (automatic)
- `htop` is better version of `top` command (we alias it instead in .zshrc)
- `lsd` is prettier version of `ls` command (we alias it instead in .zshrc)
- `bat` is prettier version of `cat` command (we alias it instead in .zshrc)
- `fd` is aliased in .zshrc as `searchFiles` and finds within directories filenames
- `ripgrep` looks within files for strings
- `git` is basic requirement for version control
- `gvim` is basic requirement for file editor, gvim instead of vim for clipboard in X11
- `zsh` will be our default shell
- `yay` is will sit ontop of Pacman as our package manager accessing AUR
- `python-pip` will give us pip for python package management
```
pacman -S diff-so-fancy htop lsd bat fd ripgrep git gvim zsh yay python-pip
```
Before we start getting into stuff, lets ensure we're not commiting things we shouldn't
```
git config --global core.excludesFile '~/.gitignore'
curl https://raw.githubusercontent.com/NathanielInman/dot-files/master/.gitignore -o ~/.gitignore
git config --global user.email "nate@theoestudio.com"
git config --global user.name "Nathaniel Inman"
git config --global core.editor "vim"
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
# (if these cause issues: `sudo mdadm -Esv` or `sudo mdadm --stop /dev/md*` then `sudo mdadm --misc --scan --detail /dev/md0`)
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

# newer machines, no eth0. config DHCP make sure to edit the proper `ip link` name
# mine shows `enp5s0` for ethernet, `vim /etc/systemd/network/enp5s0` and write this:
[Match]
Name=en**

[Network]
DHCP=yes

# Now setup password
passwd

# Now lets wrap things up. after rebooting, boot to bios, ensure nvme raid is on and remove boot flash drive.
exit
umount -R /mnt
reboot

# Now after boot, login with `root` with the configured password and unncomment `multilib` within:
# if u have issues with timing out due to /tmp, just remove it from `/etc/fstab`
vim /etc/pacman.conf

# Now lets update everything:
pacman -Syyu

# Sound and bluetooth - will enable pulseaudio on user later
Pacman -S alsa-utils pulseaudio-alsa pulseaudio-bluetooth bluez-utils
systemctl start bluetooth.service
systemctl enable bluetooth.service

# Now for installing windowmanager stuff (i3)
# sysstat is to show cpu usage and other percentages on cli
Pacman -S xorg xorg-server xorg-xinit xterm i3-gaps i3blocks i3lock i3status dmenu noto-fonts sysstat

# Before we can start i3 we need graphics drivers, validate what we're using
lspci -v | grep -A1 -e VGA -e 3D
pacman -Ss nvidia # you can search for your driver this way
pacman -S nvidia nvidia-settings nvidia-utils # this is my driver stuff

# The following is outdated, but sets up a window manager to get started, substitute `nate` for your name:
useradd -m -g users -G wheel -s /bin/bash nate
passwd nate

# Now ensure user is sudoer, vim `/etc/sudoers` and uncomment this line and :wq!
%wheel ALL=(ALL) NOPASSWD: ALL

# finally set the default editor for all users to vim save this to `vim /etc/profile.d/editor.sh`
export EDITOR=vim

# helpful non-user-specific applications
# ntp - (network-time-protocol) helps ensure we're always time synchronized
# unzip - obviously helps us w/ zip files
# numlockx - helps us default to enable/disable numlock on boot for i3
pacman -S unzip ntp numlockx

# ensure time synchronization service is started and activated
systemctl enable ntpd.service --now

# login to user
login

# Let's enable pulseaudio for user
systemctl --user enable pulseaudio
systemctl --user start pulseaudio

# Ensure we're automatically logged in, `systemctl edit getty@tty1.service` and add:
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin nate --noclear %I $TERM

# Now lets have it start by default in `vim ~/.xinitrc`
exec i3

# install user-specific applications
# kitty - fast terminal that uses gpu to render things
sudo pacman -S kitty

# Make basic home folders
mkdir ~/Sites #will hold our projects
mkdir ~/Pictures #will hold backgrounds etc
mkdir -p ~/.config/i3
mkdir ~/.config/i3blocks

# Grab the background and set its loader fehbg
curl https://raw.githubusercontent.com/NathanielInman/dot-files/master/arch-bg.jpg -o ~/Pictures/arch-bg.jpg
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/arch/fehbg -o ~/.fehbg

# Grab transparency files for picom and load it
curl https://raw.githubusercontent.com/NathanielInman/dot-files/master/arch/.picom.conf -o ~/.picom.conf

# Grab i3 configurations
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/arch/i3.conf -o ~/.config/i3/config
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/arch/i3blocks.conf -o ~/.config/i3blocks/config.conf

# Now grab yay for AUR
cd ~/Sites
git clone https://aur.archlinux.org/yay-git.git
cd yay-git
makepkg -si

# Now install web browser
yay -S google-chrome

# Now perform all CLI steps
```
