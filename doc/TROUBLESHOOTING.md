# Troubleshooting

Start here:

```sh
synopkg status SpotConnect     # is it actually running?
synopkg log SpotConnect        # where the log is
```

The log lives at `/var/packages/SpotConnect/target/log/spotconnect.log`. Raise verbosity
with `SPOTUPNP_LOGLEVEL="all=debug"` in
`/var/packages/SpotConnect/target/spotconnect.conf`, then restart the package.

## No speakers appear in the Spotify app

Work through these in order.

**Is the package running?** `synopkg status SpotConnect`. If it says stopped, start it
and read the log — a failed start writes its reason there and to Package Center.

**Give it 30 seconds.** Discovery re-scans on an interval; a speaker that was off when
the package started will not appear instantly.

**Is the speaker actually reachable?** It must be on the same layer-2 network as the NAS.
Discovery is multicast, and it does not cross VLANs, subnets or most guest networks
without explicit configuration.

**Is multicast being filtered?** This is the single most common cause, and it is usually
the router rather than anything on the NAS. Many consumer routers enable IGMP snooping or
"multicast filtering" by default and quietly drop the traffic mDNS and UPnP discovery
depend on. Symptoms are speakers that appear and then vanish, or appear for some clients
only. Look for IGMP snooping, multicast filtering or "AP isolation" in your router and
Wi-Fi settings.

**Is something else holding port 5353?** Some mDNS daemons claim it exclusively, which
stops SpotConnect answering queries. On a system with Avahi, set
`disallow-other-stacks=no` in `avahi-daemon.conf`.

**Is the right bridge installed?** `spotupnp` finds UPnP/DLNA speakers, `spotraop` finds
AirPlay receivers. If you installed only one and your speaker is the other kind, nothing
will show up. Check `SPOTUPNP_ENABLED` / `SPOTRAOP_ENABLED` in `spotconnect.conf`.

**Is the bound address right?** If your NAS has several interfaces, `SYNO_IP` may be
bound to the wrong one. Set it to the address on the network your speakers are on.

## The package says "stopped" but music is playing

If you see this, please open an issue — it means the liveness check is wrong.

For context: this exact class of bug hit the sibling project AirConnect-Synology for
years. Both programs daemonize themselves, and which `ps` invocation can see a daemonized
process differs between DSM and SRM, as does which column holds the PID. This package
determines both together at start time and the logic is verified on DSM 7 and on SRM, but
a device that behaves differently again is entirely possible.

## Stopping the package does not work

Same origin as above. The stop path finds processes by matching the package's own install
path in `ps` output and escalates from `SIGTERM` to `SIGKILL` after ten seconds. If a
process survives that, the log names which one. Include that line in a bug report.

## The package will not start on an older device

Read the package's own log first (`synopkg log SpotConnect`) — it checks the binary before
starting and names the reason. There are two distinct failures, with different answers.

**`version 'GLIBCXX_3.4.29' not found`** — your DSM ships a libstdc++ older than the
dynamic build needs. On `x86_64`, `x86` and `aarch64` you should not see this as a failure:
the package brings a matching library and switches to it by itself, and the log says
_"using the copy bundled with the package"_. If you do see it as a failure there, please
open an issue — something about your device differs from what was tested. On `arm`,
`armv5` and `powerpc` there is no bundled library yet, so install the **`-static`** package
of the same architecture instead; it carries its own.

**Killed by a signal immediately on startup, with no message** — the binary segfaults
before it runs. This affects the `-static` builds on kernels below 4.4.255, and nothing in
the package can work around it. Measured on an RT2600ac (kernel 4.4.60) and a DS415+
(3.10.108); a DS923+ (4.4.302+) is fine. The DS415+ is unaffected in practice, because its
dynamic package runs with the bundled library. Reported upstream as
[SpotConnect#78](https://github.com/philippe44/SpotConnect/issues/78) — if you hit this,
adding your model, DSM version and `uname -r` there is genuinely useful.

If both variants fail this way, SpotConnect 0.20.8 cannot run on that device yet. Check
with:

```sh
uname -r
grep -ao "GLIBCXX_3.4.29" /lib*/libstdc++.so.6 | head -1
cat /etc.defaults/VERSION
```

(On SRM use `/etc.defaults/VERSION`, not `/etc/VERSION` — the latter can report a stale
version.)

## Playback starts and then stops, or never starts

This is almost always the UPnP side, and almost always the HTTP content-length handling.
A Spotify track has no known length in advance, and older players react badly to a server
that says so.

Try, in `spotconnect.conf`, restarting after each change:

1. `SPOTUPNP_CONTENTLENGTH_MODE=-1` (never send a length)
2. `SPOTUPNP_CONTENTLENGTH_MODE=-3` (chunked encoding, upstream's default)
3. `SPOTUPNP_CODEC="mp3:320"` — some players support nothing else, and a few need a real
   length, which only works for formats whose size can be computed

If a player restarts the track from the beginning whenever you press pause, it is
re-requesting the whole resource. Set `use_filecache` in `config-upnp.xml` (see
[CONFIG.md](CONFIG.md)) so the track is buffered on disk, and combine it with
`SPOTUPNP_CONTENTLENGTH_MODE=0`.

## Audio stutters on an older NAS

The NAS decodes Vorbis and re-encodes for the speaker, and FLAC is the most expensive
option. Set `SPOTUPNP_CODEC="mp3:320"` and restart. Check load with `top` during
playback.

## A speaker stopped working after I changed Spotify accounts

The stored sign-in belongs to the old account. Clear it and let a new one be issued — see
[Spotify sign-ins](../README.md#spotify-sign-ins) in the README for the three ways to do
that. Afterwards, play to the speaker once from the new account.

## An AirPlay receiver refuses to play

Many software AirPlay receivers and inexpensive clones require encryption and will
silently decline without it. Set `encryption` to `1` in `config-raop.xml`.

For an **Apple TV** you need a one-time pairing key. Run `spotraop` interactively with
`-l` and follow the prompts; it writes a `<raop_credentials>` value to use afterwards.
Note that `-l` means something completely different in `spotupnp` — see
[CONFIG.md](CONFIG.md).

## The same speaker appears twice in Spotify

Two different things produce this, and only one of them needs fixing.

**`Living Room` and `Living Room+`** — expected when AirConnect runs on the same network.
The plain one is the AirPlay target, the one with `+` is the Spotify Connect device. See
the README on how the two differ.

**`Living Room+` twice** — SpotConnect is running on two machines on the same network,
for example two NAS. Each one finds the same speakers and announces its own Spotify Connect
device for each, under the same name, so Spotify has no way to tell them apart and neither
do you. Either run it on one machine only, or give one of them a distinct name by setting,
in its `spotconnect.conf`:

```sh
SPOTUPNP_NAME_FORMAT="%s+ (NAS 2)"
SPOTRAOP_NAME_FORMAT="%s+ (NAS 2)"
```

and restart the package.

## I run AirConnect too, and something is conflicting

Both packages run a UPnP stack. The defaults here are chosen to avoid AirConnect's ports
(`airupnp` uses 49154 with range 49155–49282; this package uses 49300 and 49301–49428).
If you changed either package's ports, make sure the ranges do not overlap, and remember
`SPOTUPNP_PORT` must be above 49152.

Running both at once is verified on a DS923+ — all four processes coexist on the default
ports. If you find a conflict the defaults do not avoid, that is worth an issue.

## Reporting a problem

Please include:

- Your NAS or router model and DSM/SRM version
- Which `.spk` you installed, including whether it was the `-static` one
- The make and model of the speaker
- The relevant part of the log with `SPOTUPNP_LOGLEVEL="all=debug"` set
- Whether the same speaker works from the Spotify desktop app directly, if it is capable
  of that

Problems with `spotupnp`/`spotraop` themselves — playback behaviour, protocol handling,
device compatibility — usually belong
[upstream](https://github.com/philippe44/SpotConnect/issues). Problems with installing,
starting, stopping, configuring or upgrading the package belong here.
