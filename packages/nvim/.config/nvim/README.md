# Neovim config

A standalone, lazy.nvim-based Neovim configuration. It was previously built on
NvChad v2.5 and has since been fully de-coupled from it — every plugin is now
declared and owned here under `lua/plugins/`.

## Requirements

- **Neovim ≥ 0.11** (developed on 0.12; the C#/roslyn server needs ≥ 0.12)
- **git**, **a C compiler** (gcc), **tree-sitter-cli** — for building treesitter parsers
- **A Nerd Font** terminal (icons in the statusline, bufferline, devicons)
- **ripgrep** / **fd** — used by fzf-lua
- Plugins are bootstrapped automatically by lazy.nvim on first launch; LSP servers,
  formatters and linters are installed automatically by mason.

### Language toolchains (system packages)

Some language servers/formatters are thin clients that need a language runtime on
the system (mason installs the server, not the runtime):

| Language | Needs installed |
|----------|-----------------|
| Java (jdtls)         | a JDK ≥ 17 (`jdk-openjdk`) |
| C# (roslyn, csharpier) | `.NET SDK` (`dotnet-sdk`) |
| Elixir (lexical, `mix`) | `elixir` (pulls Erlang/OTP) |
| Rust (rustaceanvim)  | `rustup` + `rust-analyzer` (mason also provides one) |

## Layout

- `init.lua` — lazy bootstrap; loads `lua/plugins/`, then options/autocmds/mappings
- `lua/options.lua`, `lua/autocmds.lua`, `lua/mappings.lua` — core editor config
- `lua/configs/lsp.lua` — shared LSP `on_attach`/capabilities/diagnostics
- `lua/plugins/*.lua` — one file per plugin (or closely related group)
- `lua/menus/*.lua` — definitions for the nvzone right-click/action menu
- `after/ftplugin/` — per-filetype overrides (markdown indent, jdtls bootstrap)

## Notable bindings

- `<leader>e` — toggle light/dark theme (catppuccin latte ↔ mocha)
- `<leader>bl` / `<leader>bh` — next/previous buffer (bufferline)
- `<RightMouse>` / `<leader>a` — action menu; `<leader>ga` — git action menu
- `<leader>ca` — code action, `<leader>ra` — rename, `gd`/`gr`/`gi` — LSP nav

## Personal bits (optional / safe to remove when adopting this config)

- `lua/plugins/discord.lua` (cord.nvim) — Discord Rich Presence
- `lua/plugins/nushell.lua` (nvim-nu) — Nushell support
- `guifont` in `lua/options.lua` — set to PragmataPro; change for GUI clients
