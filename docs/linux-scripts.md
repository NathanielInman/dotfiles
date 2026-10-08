# Linux Scripts

## Finding a window
There are times where you want to find the `class`, `title` or other attributes of running programs to write Hyprland window rules (`~/.config/hypr/rules.lua`) or swaync notification rules.

```
# attributes of the currently focused window
hyprctl activewindow

# every open window; filter with jq to test the class you plan to match
hyprctl clients -j | jq '.[] | {class, title, workspace: .workspace.name}'
```

`xprop` still works, but only for XWayland windows.

## Freeing up pacman yay or paru

```
paru -Scc
sudo pacman -Scc
```
