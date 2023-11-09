[![arch linux badge](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/) [![neovim badge](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.io/)

# Dot-Files
This contains all of my dot files and step-by-step instructions on how to build an Arch distribution similar to mine. Most configurations are detailed with comments. All dot files are purposefully compact and purposeful with little ricing.

## Table of Contents
  * [Setting Up Archlinux](https://github.com/NathanielInman/dot-files/blob/master/docs/setting-up-archlinux.md#setting-up-archlinux)
    * [Arch From Scratch](https://github.com/NathanielInman/dot-files/blob/master/docs/setting-up-archlinux.md#arch-from-scratch)
    * [First Boot](https://github.com/NathanielInman/dot-files/blob/master/docs/setting-up-archlinux.md#first-boot)
    * [CLI Configuration](https://github.com/NathanielInman/dot-files/blob/master/docs/setting-up-archlinux.md#cli-configuration)
    * [Default Applications](https://github.com/NathanielInman/dot-files/blob/master/docs/setting-up-archlinux.md#default-applications)
    * [Setting up Titan Security Key](https://github.com/NathanielInman/dot-files/blob/master/docs/setting-up-archlinux.md#setting-up-titan-security-key)
    * [Setting up Streamdeck](https://github.com/NathanielInman/dot-files/blob/master/docs/setting-up-archlinux.md#setting-up-streamdeck)
    * [Autostart Apps Using Systemd](https://github.com/NathanielInman/dot-files/blob/master/docs/setting-up-archlinux.md#autostart-apps-using-systemd)
  * [Setting Up Aws Users](https://github.com/NathanielInman/dot-files/blob/master/docs/setting-up-aws-users.md#setting-up-aws-users)
  * [Setting Up Digital Ocean](https://github.com/NathanielInman/dot-files/blob/master/docs/setting-up-digital-ocean.md#setting-up-digital-ocean)
  * [Setting Up MacOS](https://github.com/NathanielInman/dot-files/blob/master/docs/setting-up-macos.md#setting-up-macos)
  * [Setting Up Debian Or Ubuntu](https://github.com/NathanielInman/dot-files/blob/master/docs/setting-up-debian-or-ubuntu.md#setting-up-debian-or-ubuntu)
    * [i3 From Scratch](https://github.com/NathanielInman/dot-files/blob/master/docs/setting-up-debian-or-ubuntu.md#i3-from-scratch)
  * [Streamdeck Linux](https://github.com/NathanielInman/dot-files/blob/master/docs/streamdeck.md)
  * [Fonts linux](https://github.com/NathanielInman/dot-files/blob/master/docs/fonts.md)
  * [Basic Scripts](https://github.com/NathanielInman/dot-files/blob/master/docs/basic-scripts.md#basic-scripts)
    * [Packaging](https://github.com/NathanielInman/dot-files/blob/master/docs/basic-scripts.md#packaging)
    * [Deploying](https://github.com/NathanielInman/dot-files/blob/master/docs/basic-scripts.md#deploying)
    * [Monitoring Application](https://github.com/NathanielInman/dot-files/blob/master/docs/basic-scripts.md#monitoring-application)
    * [Reverse Proxy](https://github.com/NathanielInman/dot-files/blob/master/docs/basic-scripts.md#reverse-proxy)
    * [Setting Up Mongodb](https://github.com/NathanielInman/dot-files/blob/master/docs/basic-scripts.md#setting-up-mongodb)
    * [Global Git Ignore](https://github.com/NathanielInman/dot-files/blob/master/docs/basic-scripts.md#global-git-ignore)

## Who Am I

I'm a software engineer who makes Roguelikes for fun, enjoys WebGL, javascript, golang & rust.
| |
| :-: |
| [![basic summary](https://github-profile-summary-cards.vercel.app/api/cards/profile-details?username=nathanielinman)](https://github.com/nathanielinman) |
| [![Golang](https://img.shields.io/badge/Go-00ADD8?style=for-the-badge&logo=go&logoColor=white)](https://go.dev/) [![javascript](https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black)](https://tc39.es/) [![nodejs](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/en/) [![typescript](https://img.shields.io/badge/TypeScript-007ACC?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org/) [![python](https://img.shields.io/badge/Python-14354C?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/) [![rust](https://img.shields.io/badge/Rust-000000?style=for-the-badge&logo=rust&logoColor=white)](https://www.rust-lang.org/) [![lua](https://img.shields.io/badge/Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white)](https://www.lua.org/) [![R lang](https://img.shields.io/badge/R-276DC3?style=for-the-badge&logo=r&logoColor=white)](https://www.r-project.org/) |
| [![linkedin](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin/in/nathanielinman) [![goodreads](https://img.shields.io/badge/Goodreads-372213?style=for-the-badge&logo=goodreads&logoColor=white)](https://www.goodreads.com/user/show/95582054-nathaniel-inman) [![github](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/nathanielinman) [![gitlab](https://img.shields.io/badge/GitLab-330F63?style=for-the-badge&logo=gitlab&logoColor=white)](https://gitlab.com/nathaniel.inman) |
| [![nathanielinman's typing test profile](https://www.keyhero.com/static//badges/1603/typing-test-481109.png)](http://keyhero.com/profile/nathanielinman/?ba) |
