#!/usr/bin/env bash

# Dotfiles installer using GNU Stow
# https://www.gnu.org/software/stow/

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$DOTFILES_DIR/packages"
TARGET_DIR="$HOME"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# All available packages (directories in packages/)
get_packages() {
    local packages=()
    for dir in "$PACKAGES_DIR"/*/; do
        dir_name=$(basename "$dir")
        packages+=("$dir_name")
    done
    echo "${packages[@]}"
}

usage() {
    echo -e "${BLUE}Dotfiles Installer${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS] [PACKAGES...]"
    echo ""
    echo "Options:"
    echo "  -l, --list      List all available packages"
    echo "  -a, --all       Install all packages"
    echo "  -u, --unstow    Uninstall (unstow) packages"
    echo "  -r, --restow    Restow packages (useful after updates)"
    echo "  -n, --dry-run   Show what would be done without making changes"
    echo "  -s, --setup-system  Run optional system-level configuration (requires sudo)"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -l                  # List available packages"
    echo "  $0 -a                  # Install all packages"
    echo "  $0 nvim zsh tmux       # Install specific packages"
    echo "  $0 -u nvim             # Uninstall nvim package"
    echo "  $0 -r nvim             # Restow nvim (after pulling updates)"
    echo "  $0 -n -a               # Dry-run: show what would be installed"
    echo "  $0 -s                  # Run system-level configuration prompts"
    echo ""
}

list_packages() {
    echo -e "${BLUE}Available packages:${NC}"
    echo ""
    for pkg in $(get_packages); do
        if is_stowed "$pkg"; then
            echo -e "  ${GREEN}[installed]${NC} $pkg"
        else
            echo -e "  ${YELLOW}[available]${NC} $pkg"
        fi
    done
    echo ""
}

is_stowed() {
    local pkg="$1"
    local pkg_dir="$PACKAGES_DIR/$pkg"

    # Check for root-level dotfiles
    for item in "$pkg_dir"/.*; do
        if [[ -e "$item" && "$(basename "$item")" != "." && "$(basename "$item")" != ".." ]]; then
            local target="$TARGET_DIR/$(basename "$item")"
            if [[ -L "$target" ]]; then
                return 0
            fi
        fi
    done

    # Check for .config directory items
    if [[ -d "$pkg_dir/.config" ]]; then
        for item in "$pkg_dir/.config"/*; do
            if [[ -e "$item" ]]; then
                local target="$TARGET_DIR/.config/$(basename "$item")"
                if [[ -L "$target" ]]; then
                    return 0
                fi
            fi
        done
    fi

    return 1
}

stow_package() {
    local pkg="$1"
    local action="$2"
    local dry_run="$3"

    local stow_opts=("-v" "-t" "$TARGET_DIR" "-d" "$PACKAGES_DIR")

    if [[ "$dry_run" == "true" ]]; then
        stow_opts+=("-n")
    fi

    case "$action" in
        install)
            echo -e "${GREEN}Installing${NC} $pkg..."
            stow "${stow_opts[@]}" "$pkg"
            ;;
        unstow)
            echo -e "${YELLOW}Uninstalling${NC} $pkg..."
            stow "${stow_opts[@]}" -D "$pkg"
            ;;
        restow)
            echo -e "${BLUE}Restowing${NC} $pkg..."
            stow "${stow_opts[@]}" -R "$pkg"
            ;;
    esac
}

setup_system() {
    echo -e "${BLUE}System-level configuration${NC}"
    echo ""

    # OpenVPN3 + systemd-resolved DNS integration
    if command -v openvpn3 &> /dev/null && command -v openvpn3-admin &> /dev/null; then
        local current_config
        current_config=$(sudo cat /var/lib/openvpn3/netcfg.json 2>/dev/null || echo "")
        if echo "$current_config" | grep -q '"systemd_resolved" : true'; then
            echo -e "  ${GREEN}[configured]${NC} openvpn3 systemd-resolved DNS"
        else
            echo -n -e "  ${YELLOW}[available]${NC} Configure openvpn3 to use systemd-resolved for DNS? [y/N] "
            read -r answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                sudo mkdir -p /var/lib/openvpn3
                sudo openvpn3-admin netcfg-service --config-set systemd-resolved true
                echo -e "  ${GREEN}[configured]${NC} openvpn3 systemd-resolved DNS"
            else
                echo -e "  ${YELLOW}[skipped]${NC} openvpn3 systemd-resolved DNS"
            fi
        fi
    fi

    # openvpn3-tun-dns@tun0 — attach CloudConnexa DNS to the tunnel link.
    # netcfg doesn't apply the VPN-pushed DNS, so internal DT hosts won't resolve
    # without this. WantedBy the tun0 device unit, so it re-runs on every connect.
    if command -v openvpn3 &> /dev/null; then
        local tundns_script_src="$DOTFILES_DIR/scripts/openvpn3-tun-dns"
        local tundns_script_dst="/usr/local/bin/openvpn3-tun-dns"
        local tundns_unit_src="$DOTFILES_DIR/etc/systemd/system/openvpn3-tun-dns@.service"
        local tundns_unit_dst="/etc/systemd/system/openvpn3-tun-dns@.service"
        if [[ -x "$tundns_script_dst" ]] && cmp -s "$tundns_script_src" "$tundns_script_dst" \
            && [[ -f "$tundns_unit_dst" ]] && cmp -s "$tundns_unit_src" "$tundns_unit_dst" \
            && systemctl is-enabled openvpn3-tun-dns@tun0.service &>/dev/null; then
            echo -e "  ${GREEN}[configured]${NC} openvpn3-tun-dns@tun0 DNS hook"
        else
            echo -n -e "  ${YELLOW}[available]${NC} Install openvpn3 tunnel DNS hook (resolves internal DT hosts)? [y/N] "
            read -r answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                sudo install -Dm755 "$tundns_script_src" "$tundns_script_dst"
                sudo install -Dm644 "$tundns_unit_src" "$tundns_unit_dst"
                sudo systemctl daemon-reload
                sudo systemctl enable openvpn3-tun-dns@tun0.service
                echo -e "  ${GREEN}[configured]${NC} openvpn3-tun-dns@tun0 DNS hook"
            else
                echo -e "  ${YELLOW}[skipped]${NC} openvpn3-tun-dns@tun0 DNS hook"
            fi
        fi
    fi

    # hyprpm pacman hook — rebuild plugins after Hyprland upgrades
    if command -v hyprpm &> /dev/null; then
        local hook_src="$DOTFILES_DIR/etc/pacman.d/hooks/hyprpm.hook"
        local hook_dst="/etc/pacman.d/hooks/hyprpm.hook"
        if [[ -f "$hook_dst" ]] && sudo grep -q "su $USER -c" "$hook_dst" 2>/dev/null; then
            echo -e "  ${GREEN}[configured]${NC} hyprpm pacman hook"
        else
            echo -n -e "  ${YELLOW}[available]${NC} Install pacman hook to rebuild hyprpm plugins after Hyprland upgrades? [y/N] "
            read -r answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                sed "s/__USER__/$USER/g" "$hook_src" | sudo install -Dm644 /dev/stdin "$hook_dst"
                echo -e "  ${GREEN}[configured]${NC} hyprpm pacman hook"
            else
                echo -e "  ${YELLOW}[skipped]${NC} hyprpm pacman hook"
            fi
        fi
    fi

    # Hyprland launcher — sets NVIDIA/Wayland env then execs Hyprland's own
    # watchdog (/usr/bin/start-hyprland). Must be named hypr-launch, NOT
    # start-hyprland, or it shadows Hyprland's launcher on PATH.
    local launch_src="$DOTFILES_DIR/scripts/hypr-launch"
    local launch_dst="/usr/local/bin/hypr-launch"
    if [[ -x "$launch_dst" ]] && cmp -s "$launch_src" "$launch_dst"; then
        echo -e "  ${GREEN}[configured]${NC} hypr-launch launcher"
    else
        echo -n -e "  ${YELLOW}[available]${NC} Install Hyprland launcher to $launch_dst? [y/N] "
        read -r answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            sudo install -Dm755 "$launch_src" "$launch_dst"
            # Remove the old same-named wrapper that shadowed /usr/bin/start-hyprland.
            [[ -e /usr/local/bin/start-hyprland ]] && sudo rm -f /usr/local/bin/start-hyprland
            echo -e "  ${GREEN}[configured]${NC} hypr-launch launcher"
        else
            echo -e "  ${YELLOW}[skipped]${NC} hypr-launch launcher"
        fi
    fi

    # rime-umount.service — force-unmount the Rime CIFS share early on shutdown
    # so the kernel doesn't block ~180s on the unreachable server (shutdown hang).
    local rime_src="$DOTFILES_DIR/etc/systemd/system/rime-umount.service"
    local rime_dst="/etc/systemd/system/rime-umount.service"
    if [[ -f "$rime_dst" ]] && cmp -s "$rime_src" "$rime_dst" && systemctl is-enabled rime-umount.service &>/dev/null; then
        echo -e "  ${GREEN}[configured]${NC} rime-umount shutdown service"
    else
        echo -n -e "  ${YELLOW}[available]${NC} Install rime-umount shutdown service (avoids CIFS shutdown hang)? [y/N] "
        read -r answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            sudo install -Dm644 "$rime_src" "$rime_dst"
            sudo systemctl daemon-reload
            sudo systemctl enable rime-umount.service
            echo -e "  ${GREEN}[configured]${NC} rime-umount shutdown service"
        else
            echo -e "  ${YELLOW}[skipped]${NC} rime-umount shutdown service"
        fi
    fi

    echo ""
    echo -e "${GREEN}System configuration complete!${NC}"
}

# Parse arguments
ACTION="install"
DRY_RUN="false"
PACKAGES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -l|--list)
            list_packages
            exit 0
            ;;
        -a|--all)
            PACKAGES=($(get_packages))
            shift
            ;;
        -u|--unstow)
            ACTION="unstow"
            shift
            ;;
        -r|--restow)
            ACTION="restow"
            shift
            ;;
        -s|--setup-system)
            setup_system
            exit 0
            ;;
        -n|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
        *)
            PACKAGES+=("$1")
            shift
            ;;
    esac
done

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    echo -e "${RED}Error: GNU Stow is not installed.${NC}"
    echo "Install it with: sudo pacman -S stow"
    exit 1
fi

# If no packages specified, show help
if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    usage
    exit 0
fi

# Validate packages
VALID_PACKAGES=($(get_packages))
for pkg in "${PACKAGES[@]}"; do
    if [[ ! " ${VALID_PACKAGES[*]} " =~ " ${pkg} " ]]; then
        echo -e "${RED}Error: Unknown package '$pkg'${NC}"
        echo "Run '$0 -l' to see available packages."
        exit 1
    fi
done

# Process packages
if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}Dry-run mode: showing what would be done${NC}"
    echo ""
fi

for pkg in "${PACKAGES[@]}"; do
    stow_package "$pkg" "$ACTION" "$DRY_RUN"
done

echo ""
echo -e "${GREEN}Done!${NC}"
