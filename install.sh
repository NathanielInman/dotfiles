#!/usr/bin/env bash

# Dotfiles installer using GNU Stow
# https://www.gnu.org/software/stow/

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# All available packages (directories that contain dotfiles)
get_packages() {
    local packages=()
    for dir in "$DOTFILES_DIR"/*/; do
        dir_name=$(basename "$dir")
        # Skip non-package directories
        case "$dir_name" in
            docs|scripts|usr|Pictures|.git|.aws|.claude)
                continue
                ;;
            *)
                packages+=("$dir_name")
                ;;
        esac
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
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -l                  # List available packages"
    echo "  $0 -a                  # Install all packages"
    echo "  $0 nvim zsh tmux       # Install specific packages"
    echo "  $0 -u nvim             # Uninstall nvim package"
    echo "  $0 -r nvim             # Restow nvim (after pulling updates)"
    echo "  $0 -n -a               # Dry-run: show what would be installed"
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
    local pkg_dir="$DOTFILES_DIR/$pkg"

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

    local stow_opts=("-v" "-t" "$TARGET_DIR" "-d" "$DOTFILES_DIR")

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
