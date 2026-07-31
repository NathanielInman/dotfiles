hl.on("hyprland.start", function()
  -- Session plumbing
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
  hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
  hl.exec_cmd("systemctl --user start hyprland-session.target")

  -- waybar runs as a systemd user service (enabled via `systemctl --user
  -- enable waybar`) so Restart=on-failure revives it if it segfaults, e.g.
  -- after an in-place glibc upgrade invalidates its mapped libraries.
  hl.exec_cmd("systemctl --user start waybar.service")

  hl.exec_cmd("nm-applet --indicator")
  hl.exec_cmd("blueman-applet")
  hl.exec_cmd("copyq --start-server")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("sleep 1 && ~/.config/hypr/scripts/wallpaper.sh")
  hl.exec_cmd("hypridle")
  -- swayosd-server occasionally segfaults; relaunch it so volume/mute keys keep working
  hl.exec_cmd("bash -c 'until swayosd-server; do sleep 1; done'")
  hl.exec_cmd("sway-audio-idle-inhibit")
  hl.exec_cmd("walker --gapplication-service")
  hl.exec_cmd("voxtype")

  -- App launches per workspace
  -- Chrome flags (wayland, restore-last-session) live in ~/.config/chrome-flags.conf
  hl.exec_cmd("google-chrome-stable", { workspace = "1 silent" })
  hl.exec_cmd("zoom", { workspace = "2 silent", tile = true, no_anim = true })
  hl.exec_cmd("slack", { workspace = "2 silent" })
  hl.exec_cmd("discord", { workspace = "3 silent" })
  hl.exec_cmd("kitty --directory $HOME/Sites", { workspace = "4 silent" })
  hl.exec_cmd("neovide ~/.zshrc", { workspace = "4 silent" })
  hl.exec_cmd("sleep 5 && neovide ~/Sites/notes/dt_frontend_todos.md", { workspace = "5 silent" })
end)
