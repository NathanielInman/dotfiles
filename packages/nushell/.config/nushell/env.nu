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
# Elgato Key Lights, addressed by permanent IPv6 link-local address (derived
# from the device MAC, so no DHCP lease or mDNS discovery). %enp6s0 is the
# interface they're on; brightness 3 is the left light, 50 the right.
def _keylight [addr: string, on: int, brightness: int] {
  http put -t application/json $"http://[($addr)%enp6s0]:9123/elgato/lights" {
    numberOfLights: 1, lights: [{on: $on, brightness: $brightness, temperature: 344}]
  } | ignore
}
def lightson [] {
  _keylight "fe80::3e6a:9dff:fe14:e88f" 1 3
  _keylight "fe80::3e6a:9dff:fe14:e88e" 1 50
}
def lightsoff [] {
  _keylight "fe80::3e6a:9dff:fe14:e88f" 0 3
  _keylight "fe80::3e6a:9dff:fe14:e88e" 0 50
}

# pnpm
$env.PNPM_HOME = "/home/nate/.local/share/pnpm"
$env.PATH = ($env.PATH | split row (char esep) | prepend $env.PNPM_HOME )
# pnpm end
