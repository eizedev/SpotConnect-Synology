# Configuration reference

Most installations need nothing here. The wizard asks the only three questions that
matter, and the shipped defaults are chosen so the package works without tuning.

There are two layers, and it is worth knowing which one to reach for:

1. **`spotconnect.conf`** — this package's own settings. A plain `KEY=value` file, read
   by the start script, which turns it into command-line options. This is what you edit
   for anything listed below.
2. **`config-upnp.xml` / `config-raop.xml`** — upstream's own config files, with far more
   options including per-speaker overrides. Only needed for things this package does not
   expose.

Both live in `/var/packages/SpotConnect/target/`. Restart the package after editing
either.

## `spotconnect.conf`

### Shared

| Key                               | Default             | Meaning                                                                                                        |
| --------------------------------- | ------------------- | -------------------------------------------------------------------------------------------------------------- |
| `SYNO_IP`                         | detected at install | Address both programs bind to. Change it if your NAS has several interfaces and discovery picks the wrong one. |
| `SPOTCONNECT_CREDENTIALS_ENABLED` | `1`                 | Store reusable Spotify sign-ins. Set to `0` to stay in local-discovery-only mode. See the README.              |

### `spotupnp` (UPnP/DLNA speakers)

| Key                           | Default               | Meaning                                                                                                             |
| ----------------------------- | --------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `SPOTUPNP_ENABLED`            | `1`                   | Run this bridge at all.                                                                                             |
| `SPOTUPNP_PORT`               | `49300`               | The UPnP port. **Must be above 49152.** Chosen to stay clear of AirConnect's `airupnp`.                             |
| `SPOTUPNP_PORTRANGE`          | `49301:128`           | `start:count` for the HTTP/RTP ports. Fix these if you want firewall rules; without a range the ports are random.   |
| `SPOTUPNP_CODEC`              | `flc` _(provisional)_ | What is sent to the player: `mp3[:rate]`, `aac[:rate]`, `vorbis[:rate]`, `opus[:rate]`, `flc[:0..9]`, `wav`, `pcm`. |
| `SPOTUPNP_CONTENTLENGTH_MODE` | `0` _(provisional)_   | How HTTP length is reported. See below.                                                                             |
| `SPOTUPNP_RATE`               | `320`                 | Spotify bitrate: `96`, `160` or `320`. Upstream defaults to 160.                                                    |
| `SPOTUPNP_NAME_FORMAT`        | `%s+`                 | Device naming. C format string, `%s` is the speaker's own name.                                                     |
| `SPOTUPNP_LOGLEVEL`           | `all=info`            | `<log>=<level>`; logs `all`, `main`, `util`, `upnp`; levels `error`, `warn`, `info`, `debug`, `sdebug`.             |

### `spotraop` (AirPlay receivers)

| Key                    | Default     | Meaning                                              |
| ---------------------- | ----------- | ---------------------------------------------------- |
| `SPOTRAOP_ENABLED`     | `1`         | Run this bridge at all.                              |
| `SPOTRAOP_PORTRANGE`   | `49430:128` | `start:count` for HTTP/RTP ports.                    |
| `SPOTRAOP_CODEC`       | `alac`      | `alac` or `pcm`. This bridge takes no other formats. |
| `SPOTRAOP_RATE`        | `320`       | Spotify bitrate.                                     |
| `SPOTRAOP_NAME_FORMAT` | `%s+`       | Device naming.                                       |
| `SPOTRAOP_LOGLEVEL`    | `all=info`  | Logs here are `all`, `main`, `util`, `raop`.         |

Note there is no `SPOTRAOP_PORT`: `spotraop` binds to an address only, with no port of
its own, unlike `spotupnp`.

## The two programs are not interchangeable

This trips people up when reading upstream's documentation, so it is worth stating
plainly. The same option letter means different things:

| Option | `spotupnp`                                    | `spotraop`       | AirConnect's `airupnp`   |
| ------ | --------------------------------------------- | ---------------- | ------------------------ |
| `-l`   | flow mode (one continuous stream)             | Apple TV pairing | latency                  |
| `-b`   | `<ip>[:<port>]`                               | `<ip>` only      | `<ip>[:<port>]`          |
| `-g`   | HTTP content-length mode                      | does not exist   | HTTP content-length mode |
| `-c`   | `mp3`/`aac`/`vorbis`/`opus`/`flc`/`wav`/`pcm` | `alac`/`pcm`     | —                        |

If you are copying a command line from upstream's README or from a forum post, check
which binary it was written for.

## Content-length mode

`SPOTUPNP_CONTENTLENGTH_MODE` exists because a streamed Spotify track has no known length
in advance, and UPnP players disagree violently about how a server should admit that.

| Value | Behaviour                                                                                                             |
| ----- | --------------------------------------------------------------------------------------------------------------------- |
| `-3`  | Chunked transfer encoding. Upstream's default and correct HTTP/1.1, but some players that claim 1.1 cannot handle it. |
| `-2`  | Send a length only when it can be computed (`wav`, `pcm`).                                                            |
| `-1`  | Never send a length.                                                                                                  |
| `0`   | Send a generously estimated length.                                                                                   |
| `<n>` | Send exactly this value.                                                                                              |

This package ships `0` because its sibling project arrived at the same value for the same
reason: it is the mode that the widest range of older players tolerate. If a player
refuses to start or stops after a few seconds, this is the first thing to change — try
`-1`, then `-3`.

**Provisional.** This default has not yet been measured against real players from this
package; it is inherited reasoning, not a test result.

## Codec choice

`flc` (FLAC) is upstream's recommendation and preserves the decoded stream exactly, at
the cost of the most CPU on the NAS and the most bandwidth. `mp3:320` is much cheaper and
supported essentially everywhere — some players, notably some Pioneer/Phorus/Play-Fi
models, support nothing else.

There is no audible quality argument for FLAC over a high-bitrate lossy format here: the
source is already lossy Vorbis, so FLAC is losslessly wrapping something that is not
lossless to begin with. Choose it for compatibility reasons, not fidelity ones.

**Provisional.** The shipped default has not been measured on an older NAS. If you see
stuttering on a lower-powered model, `mp3:320` is the first thing to try.

## Things only upstream's config.xml can do

Useful options that this package does not surface as its own keys, set in
`config-upnp.xml` or `config-raop.xml` instead:

- `flow` — send all tracks as one continuous stream instead of track by track. Helps
  players that stumble between tracks; costs reliable track position and usually
  metadata.
- `gapless` — use the player's gapless handoff, where it supports it.
- `use_filecache` — buffer whole tracks on disk. The workaround for players that re-request
  a track from the beginning when you press pause.
- `remove_timeout` — set `-1` to stop players being dropped from the list prematurely.
- `encryption` (`spotraop`) — required by many software AirPlay receivers and cheap
  clones, which will silently refuse to stream without it.
- `alac_encode` (`spotraop`) — ALAC versus raw PCM.
- `artwork` — a fixed image to show on the player in flow mode.
- **Per-device sections**, which is the real reason to go here: every common option can be
  set inside a `<device>` block to apply to one speaker only, overriding the global value.

Generate a fully commented reference file with every available option:

```sh
sudo -u spotconnect /var/packages/SpotConnect/target/spotupnp -i /tmp/reference.xml
```

That discovers your players, writes the file and exits. Copy the parts you need into
`config-upnp.xml` rather than replacing it wholesale.

> **Do not share a generated file as-is.** Upstream writes its own Spotify application
> `<client_id>` and `<client_secret>` into it in clear text — the ones compiled into the
> binary, which upstream deliberately keeps out of its published source. If you paste a
> config into a forum thread or a bug report, strip those two tags first. The package's own
> `config-upnp.xml` / `config-raop.xml` do not contain them: they are created as empty
> skeletons, and nothing here runs `-i` or `-I` on your behalf.
>
> Upstream stopped writing those two tags in 0.20.9
> ([#79](https://github.com/philippe44/SpotConnect/issues/79), confirmed on hardware).
> This package still ships 0.20.8, so check before sharing until it updates.

## What is deliberately not configurable

**The credentials directory.** Its path is derived, not read from the config, because a
settable path invites pointing it at a shared folder — and reusable Spotify tokens must
never sit in one. See the README for the full reasoning.

**Spotify username and password.** Upstream accepts `-U`/`-P`; this package does not
expose them. Anything on a process's command line is readable by every local user through
`ps`, and there is no need for them: Spotify issues a device token on first playback
instead.
