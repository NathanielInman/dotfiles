# OpenVPN3 + DigitalTurbine VPN DNS

## The problem

The DigitalTurbine VPN is **OpenVPN CloudConnexa** (gateway `us-mci.gw.openvpn.com`),
connected via `openvpn3` on Linux from `~/dt.ovpn`. The tunnel and routing work,
but `openvpn3-service-netcfg` does **not** attach the VPN-pushed DNS server +
search domain to the `tun0` link in `systemd-resolved`.

Result: internal hosts like `grafana.internal.ss-prod.digitalturbine.com` fail to
resolve. The query falls through to the LAN router (`192.168.1.1`), which knows
nothing about DT's private zones. Browser shows the host as unreachable.

This surfaced after rebuilding the `openvpn3` AUR package: the rebuild reset the
packaged netcfg D-Bus service, which launches netcfg with **no DNS resolver
backend** (no `--systemd-resolved` flag, and `/var/lib/openvpn3/netcfg.json`
didn't exist). Setting `systemd_resolved true` is necessary but was **not
sufficient** — even then the rebuilt client didn't forward the pushed DNS to
netcfg. So we apply the DNS ourselves.

## Diagnosing

```sh
# Tunnel up? (should show Device: tun0, "Client connected")
openvpn3 sessions-list

# Is DNS attached to the tunnel? BROKEN if there is no "DNS" scope / no servers.
resolvectl status tun0

# Is the in-tunnel resolver actually working? (this should resolve even when the
# system resolver can't — proves it's purely a "DNS not applied to tun0" issue)
dig @100.127.255.250 grafana.internal.ss-prod.digitalturbine.com
# -> 10.242.16.28
```

The CloudConnexa internal resolvers are `100.127.255.250` (anycast) and the
gateway-side `100.96.0.1`. They resolve DT private zones and forward public
names upstream.

## The fix (automated)

`install.sh` (System-level configuration step) installs two things:

1. `scripts/openvpn3-tun-dns` -> `/usr/local/bin/openvpn3-tun-dns`
   Runs `resolvectl dns/domain/default-route` to point the tunnel at the
   CloudConnexa resolvers and route only `~digitalturbine.com` lookups through it.
2. `etc/systemd/system/openvpn3-tun-dns@.service`, enabled as
   `openvpn3-tun-dns@tun0.service`. It is `WantedBy` the `tun0` **device unit**,
   so systemd runs it automatically every time the kernel (re)creates the
   interface — i.e. on every VPN connect.

It also persists `openvpn3-admin netcfg-service --config-set systemd-resolved true`.

### Why this survives openvpn3 rebuilds

The hook is decoupled from the package. None of its files are owned by
`openvpn3` (`pacman -Qo` reports them unowned), and it triggers off the kernel
creating the interface, not off any openvpn3 internal. A future rebuild that
again breaks netcfg's own DNS handling won't affect the hook — it re-applies DNS
on top regardless.

## When it could still need attention

- **Interface renamed off `tun0`.** The trigger is bound to `tun0`. The mainline
  `ovpn.ko` DCO module is present; if openvpn3 ever switches to kernel DCO and
  names the interface differently (e.g. `ovpn0`), `@tun0` won't fire. Fix:
  re-enable for the new name (`systemctl enable openvpn3-tun-dns@<iface>.service`),
  or replace the per-device enable with a udev rule matching `tun*`/`ovpn*`:

  ```
  # /etc/udev/rules.d/90-openvpn3-tun-dns.rules
  ACTION=="add", SUBSYSTEM=="net", KERNEL=="tun*|ovpn*", \
    TAG+="systemd", ENV{SYSTEMD_WANTS}+="openvpn3-tun-dns@$name.service"
  ```

- **CloudConnexa changes resolver IPs, or DT adds zones outside
  `*.digitalturbine.com`.** Edit the `DNS_SERVERS` / `ROUTE_DOMAINS` arrays at the
  top of `scripts/openvpn3-tun-dns`.

## Manual one-shot (if the hook is ever missing)

```sh
sudo resolvectl dns tun0 100.127.255.250 100.96.0.1
sudo resolvectl domain tun0 '~digitalturbine.com'
sudo resolvectl default-route tun0 false
```

Not persistent — wiped on the next reconnect. The systemd hook above is the
durable version.
