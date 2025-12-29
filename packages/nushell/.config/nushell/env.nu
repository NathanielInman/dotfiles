# env.nu
#
# Installed by:
# version = "0.104.1"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
mkdir ~/.cache/carapace
carapace _carapace nushell | save --force ~/.cache/carapace/init.nu
# GL_TOKEN and GOOGLE_CLOUD_PROJECT set via local environment
export-env { $env.PNPM_HOME = $"($env.HOME)/.local/share/pnpm" }
export-env { $env.PATH = ($env.PATH | split row (char esep) | prepend $env.PNPM_HOME ) }
def lightson [] {
  keylightctl switch --light 8A95 on
  keylightctl switch --light 9F74 on
}
def lightsoff [] {
  keylightctl switch --light 8A95 off
  keylightctl switch --light 9F74 off
}

# pnpm
$env.PNPM_HOME = "/home/nate/.local/share/pnpm"
$env.PATH = ($env.PATH | split row (char esep) | prepend $env.PNPM_HOME )
# pnpm end
