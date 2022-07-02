## Setting Up Manjaro Or Archlinux
### Arch From Scratch
When all else fails, the best installation guide is [the official arch wiki](https://wiki.archlinux.org/index.php/installation_guide).

```
# to start, lets ensure the internet is connected and sync time
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
# xorg, xorg-server, xorg-xinit - display server
# xterm - terminal emulator for X window system
# i3-gaps - spaces between windows/containers on i3wm
# i3blocks - status tray components
# i3status - status tray
# rofi - hotkey app opener overlay, alternative to dmenu & ulauncher
# noto-fonts - emoji extras & base fonts
# sysstat - iostat, isag, mpstat, pidstat, sadf, sar (cpu usage etc on cli)
Pacman -S xorg xorg-server xorg-xinit xterm i3-gaps i3blocks i3lock i3status rofi noto-fonts sysstat

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
sudo pacman -S kitty stow

# Make basic home folders
mkdir ~/Sites #will hold our projects
mkdir ~/Pictures #will hold backgrounds etc

# Now grab all of the dot files
cd ~/Sites
git clone https://github.com/nathanielinman/dot-files.git
stow --dir=~=Sites/dot-files --target=~/
# if at any point you want to remove the symlinks `stow -D .` from within the source repo folder

# Now grab paru for AUR, used to use yay but Rust ftw :)
cd ~/Sites
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

# Now install web browser
yay -S google-chrome

# Now perform all CLI Configuration below
```

### CLI Configuration
We start by using our package manager `pacman` to get all necessary binaries. We'll omit `node` as it will be managed by it's own version manager.
- `diff-so-fancy` helps make cli `git diff` look good (automatic)
- `exa` is prettier version of `ls` command (we alias it instead in .zshrc)
- `bat` is prettier version of `cat` command (we alias it instead in .zshrc)
- `fd` is aliased in .zshrc as `searchFiles` and finds within directories filenames
- `ripgrep` looks within files for strings
- `git` is basic requirement for version control
- `gvim` is basic requirement for file editor, gvim instead of vim for clipboard in X11
- `zsh` will be our default shell
- `yay` is will sit ontop of Pacman as our package manager accessing AUR
- `python-pip` will give us pip for python package management
- `xsel` will allow "clipboard" input and outputs via cli. see alias pbcopy & pbpaste aliases in .zshrc
- `task` is a very simple cli todo app named taskwarrior
```
pacman -S diff-so-fancy exa bat fd ripgrep git gvim zsh yay python-pip xsel task
```
Now we update our python package manager
```
pip3 install --upgrade pip
```
Now for installing vim package manager
```
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```
Now that Vundler is installed, we can install all the plugins.
```
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
Install node js stuff, we'll actually manage this with `n` and `npm` itself later on
```
yay -S nodejs npm
```
Now lets add npm global ability
```
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
# now open ~/.zshrc with vim and add "~/.npm-global/bin" to PATH
```
Now install our nodejs version manager and couple other helpful node things. It may be worthwhile to also ensure you don't have to use `sudo` in order to install `npm` packages in the future, those lines follow.
```
npm install -g npm npm-check-updates n

# make cache folder (if missing) and take ownership
sudo mkdir -p /usr/local/n
sudo chown -R $(whoami) /usr/local/n

# make sure the required folders exist (safe to execute even if they already exist)
sudo mkdir -p /usr/local/bin /usr/local/lib /usr/local/include /usr/local/share

# take ownership of Node.js install destination folders
sudo chown -R $(whoami) /usr/local/bin /usr/local/lib /usr/local/include /usr/local/share
```
Now we'll install Rust:
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
Now some rust utils:
- `rusti-cal` is a better calendar
```
cargo install rusti-cal
```
Now for any other essentials for arch
- `slack-desktop` for work, quite a bit better than regular browser version
- `pagraphcontrol-git` like amixer but pretty and allows enabling/adjusting things at runtime
- `ttf-joypixels` adds support for emoji's within kitty terminal and elsewhere
- `vit` is a TUI for taskwarrior
- `ncdu` NCurses Disk Usage shows what files/folders are occupying how much space
- `nnn` is a filemanager for the terminal with workspaces and vim-like controls
- `glow` is for cating out or reading markdown files in terminal
- `glances` is better version of `top` command (we alias it instead in .zshrc)
- `procs` is a better version of `ps` command (we alias it instead in .zshrc)
- `tokei` analyzes a folders programming language, loc, comments, etc
- `zoxide` allows jumpting to random folders, inspired by z and autojump
- `fzf` is a fuzzy finder for files usable in vim or cli
- `didyoumean` is a spell-checking app
- `translate-shell` is a translation app
- `udict` urban dictionary
- `neofetch` cli info tool
- `sdcv-git` cli dictionary
- `xsv` is a cli for splitting/joining/analyzing csv files
- `zk` is a note-taking TUI with search built-in
```
yay -S slack-desktop pagraphcontrol-git feh ttf-joypixels ncdu nnn glow glances procs tokei zoxide fzf didyoumean translate-shell udict neofetch sdcv-git xsv zk
```
Now grab the dictionary file for sdcv:
```
sudo mkdir -p /usr/share/stardict/dic/
sudo wget -c https://web.archive.org/web/20200630200122/http://download.huzheng.org/dict.org/stardict-dictd_www.dict.org_gcide-2.4.2.tar.bz2 -O /tmp/dict.tar.bz2 && sudo tar -xvjf /tmp/dict.tar.bz2 -C /usr/share/stardict/dic/
```
Now sync notes for `zk` into Sites:
```
cd ~/Sites
git clone https://github.com/nathanielinman/notes.git
```
Now sync tasks for `taskwarrior` and `vit`:
```
git clone https://github.com/nathanielinman/tasks.git ~/.task
```