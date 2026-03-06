# Dot-Files

This contains all of my dot files and step-by-step instructions on how to build an Arch distribution similar to mine. Most configurations are detailed with comments. All dot files are purposefully compact with little ricing.

![Full-screen Example of Desktop](/Pictures/fullscreen.png)

## Installation

Aside from referencing the configuration files directly, you can use stow to automatically install any one or multiple of the configurations in this repository. This repository uses [GNU Stow](https://www.gnu.org/software/stow/) for managing symlinks.

```bash
# Packages are 'installed' by merely symlinking the files to their destinations
sudo pacman -S stow

# Clone the repository
git clone https://github.com/NathanielInman/dot-files.git ~/Sites/dot-files
cd ~/Sites/dot-files

# List available packages
./install.sh -l

# Install all packages
./install.sh -a

# Install specific packages
./install.sh nvim zsh starship

# Uninstall a package
./install.sh -u nvim

# Restow after pulling updates
./install.sh -r nvim
```

### Available Packages

| Package       | Description           |
| ------------- | --------------------- |
| `wezterm`     | Terminal emulator     |
| `git`         | Git configuration     |
| `hyprland`    | Wayland compositor    |
| `nushell`     | Modern shell          |
| `nvim`        | NeoVim with NvChad    |
| `walker`      | Application launcher  |
| `starship`    | Shell prompt          |
| `swaync`      | Notification center   |
| `vim`         | Vim configuration     |
| `waybar`      | Status bar            |
| `zsh`         | Zsh + Oh-My-Zsh theme |

> [!TIP]
> Clicking on the icons below will lead directly to this repositories documentation on how to setup said operating system or tool.

## My Everyday Stack

[![arch linux badge](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://github.com/NathanielInman/dot-files/blob/master/docs/setting-up-archlinux.md#setting-up-archlinux) [![neovim badge](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)](https://nvchad.com/) [![zsh badge](https://img.shields.io/badge/Zsh-F15A24?style=for-the-badge&logo=Zsh&logoColor=white)](https://github.com/NathanielInman/dot-files/blob/master/docs/basic-scripts.md#basic-scripts) [![pragmata pro badge](https://img.shields.io/badge/pragmata%20pro-1BB91F?style=for-the-badge&logo=educative&logoColor=white)](https://github.com/NathanielInman/dot-files/blob/master/docs/fonts.md)

## My Common Stacks

[![cloudflare badge](https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=Cloudflare&logoColor=white)](https://github.com/NathanielInman/dot-files/blob/master/docs/setting-up-digital-ocean.md#setting-up-digital-ocean) [![claude badge](https://img.shields.io/badge/Claude-D97757?style=for-the-badge&logo=claude&logoColor=white)](https://claude.ai/) [![gemini badge](https://img.shields.io/badge/Google%20Gemini-8E75B2?style=for-the-badge&logo=googlegemini&logoColor=white)](https://gemini.google.com/) [![proton mail badge](https://img.shields.io/badge/proton%20mail-6D4AFF?style=for-the-badge&logo=protonmail&logoColor=white)](https://proton.me/) [![illustrator badge](https://img.shields.io/badge/Adobe%20Illustrator-FF9A00?style=for-the-badge&logo=adobe%20illustrator&logoColor=white)](https://www.adobe.com/products/illustrator.html) [![photoshop badge](https://img.shields.io/badge/Adobe%20Photoshop-31A8FF?style=for-the-badge&logo=Adobe%20Photoshop&logoColor=black)](https://www.adobe.com/products/photoshop.html) [![blender badge](https://img.shields.io/badge/blender-%23F5792A.svg?style=for-the-badge&logo=blender&logoColor=white)](https://www.blender.org/) [![bevy badge](https://img.shields.io/badge/Bevy-232326?style=for-the-badge&logo=bevy&logoColor=white)](https://bevyengine.org/) [![godot badge](https://img.shields.io/badge/Godot-478CBF?style=for-the-badge&logo=GodotEngine&logoColor=white)](https://godotengine.org/) [![steam badge](https://img.shields.io/badge/Steam-000000?style=for-the-badge&logo=steam&logoColor=white)](https://store.steampowered.com/) [![chrome badge](https://img.shields.io/badge/Google_chrome-4285F4?style=for-the-badge&logo=Google-chrome&logoColor=white)](https://www.google.com/chrome/)

## Who Am I

I'm a software engineer who makes Roguelikes for fun, enjoys WebGL, javascript, golang & rust.
| |
| :-: |
| [![basic summary](https://github-profile-summary-cards.vercel.app/api/cards/profile-details?username=nathanielinman)](https://github.com/nathanielinman) |
| [![Golang](https://img.shields.io/badge/Go-00ADD8?style=for-the-badge&logo=go&logoColor=white)](https://go.dev/) [![javascript](https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black)](https://tc39.es/) [![nodejs](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/en/) [![typescript](https://img.shields.io/badge/TypeScript-007ACC?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org/) [![python](https://img.shields.io/badge/Python-14354C?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/) [![rust](https://img.shields.io/badge/Rust-000000?style=for-the-badge&logo=rust&logoColor=white)](https://www.rust-lang.org/) [![lua](https://img.shields.io/badge/Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white)](https://www.lua.org/) [![R lang](https://img.shields.io/badge/R-276DC3?style=for-the-badge&logo=r&logoColor=white)](https://www.r-project.org/) |
| [![linkedin](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin/in/nathanielinman) [![goodreads](https://img.shields.io/badge/Goodreads-372213?style=for-the-badge&logo=goodreads&logoColor=white)](https://www.goodreads.com/user/show/95582054-nathaniel-inman) [![github](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/nathanielinman) [![gitlab](https://img.shields.io/badge/GitLab-330F63?style=for-the-badge&logo=gitlab&logoColor=white)](https://gitlab.com/nathaniel.inman) [![codepen badge](https://img.shields.io/badge/Codepen-000000?style=for-the-badge&logo=codepen&logoColor=white)](https://codepen.io/NathanielInman) |
| ![nathanielinman's top spotify](https://github.com/NathanielInman/dot-files/blob/master/Pictures/spotify_summary_nathanielinman2023.png) |
| [![nathanielinman's typing test profile](https://www.keyhero.com/static//badges/1603/typing-test-481109.png)](http://keyhero.com/profile/nathanielinman/?ba) |
