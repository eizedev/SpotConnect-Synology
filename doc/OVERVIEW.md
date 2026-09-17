# What this actually does, and why it is on a NAS

The [README](../README.md) gives the short version. This document is for the questions
that come after it: what the audio path really looks like, what changes day to day, how
this sits next to AirConnect, and where the honest limits are.

## The one thing worth understanding

Spotify Connect is not "sending audio to a speaker". It is the opposite: the **speaker**
holds a session with Spotify's servers and pulls the audio itself. Your phone only tells
it what to play. That is why, with a Spotify Connect speaker, you can lock your phone,
take a call, leave the house, or hand control to someone else, and nothing happens to the
music.

Most speakers made before roughly 2015 cannot do that. They speak UPnP/DLNA, or AirPlay,
and they will happily accept an audio stream — but only if something else holds the
session and does the work. SpotConnect is that something else, and this package makes
your NAS run it.

## Two audio paths, side by side

Say you own an old Denon receiver on the network and you also run AirConnect.

**Playing to it from Spotify over AirPlay (what AirConnect gives you):**

```text
Spotify servers
      |
      v
  your iPhone            <- decodes the stream, plays it, must stay connected
      |  AirPlay (push)
      v
  AirConnect on the NAS
      |  UPnP
      v
  the Denon
```

The phone is a link in the chain. AirPlay is a push protocol — the source device sends.
Walk out of Wi-Fi range and the chain breaks.

**Playing to it as a Spotify Connect device (what this package gives you):**

```text
Spotify servers
      |
      v
  SpotConnect on the NAS  <- holds the session, decodes Vorbis, re-encodes
      |  UPnP
      v
  the Denon

  your phone  ---- control messages only ---->  (not in the audio path)
```

The phone is a remote. It can go flat, go away, or be replaced by a completely different
device mid-song.

## What that changes day to day

- Tap `Kitchen+` in Spotify in the morning and take the phone with you into the bathroom.
  The music stays in the kitchen.
- The amplifier in the workshop keeps playing while the phone charges in another room.
- A guest opens Spotify on their own phone and takes over the speaker. No pairing, no
  "please connect to our Wi-Fi first" beyond being on the network.
- An **Android** household gets this at all. AirPlay does not exist there, so bridging
  Spotify through AirPlay is simply not an option — this is the single clearest reason to
  add SpotConnect next to AirConnect.
- Home automation can drive it. Because a signed-in speaker registers itself with
  Spotify's servers, it is addressable from Spotify's Web API and from integrations built
  on it, so "play this playlist on the old amplifier at 07:00" becomes something you can
  script. Routing phone audio can never be scripted that way.
- You can start playback from outside the house. The audio still comes from the NAS on
  your LAN; it is the control that is remote.

The last two only work with stored sign-ins, which is the default. See the README's
[Spotify sign-ins](../README.md#spotify-sign-ins) section for what is stored and why no
password is involved.

## Why a NAS and not a Raspberry Pi or a PC

Nothing stops you running SpotConnect on any always-on Linux box, and upstream documents
exactly that. The argument for the NAS is not technical superiority, it is that a Spotify
Connect device only exists while its bridge runs:

- A laptop sleeps. The speaker vanishes from the device list, and you are back to waking
  a machine before you can play anything — the exact dependency this was supposed to
  remove.
- A NAS is already on, usually wired. Wired matters more than it sounds: discovery is
  mDNS multicast, and a sleeping or power-saving Wi-Fi adapter is a common cause of
  speakers appearing and disappearing.
- DSM owns the lifecycle. Autostart after reboot, restart after a DSM update, install and
  upgrade through Package Center, logs through `synopkg log`. None of that has to be
  built or maintained by you.
- A Raspberry Pi does all of the above too. If you already have one running, it is a
  perfectly good host. The point is that most people with a Synology already own the
  always-on machine and do not need a second one.

What the package adds beyond "the binary, but on a NAS": a wizard instead of command-line
flags, tuned defaults instead of upstream's bare ones, log rotation, a restricted
directory for the Spotify tokens that upstream writes world-readable, and config that
survives upgrades.

## Running this alongside AirConnect

This is the normal case, not an edge case, and the two do different jobs:

| You want …                                               | Use                                           |
| -------------------------------------------------------- | --------------------------------------------- |
| Spotify, controlled from any platform, phone-independent | SpotConnect                                   |
| Apple Music, YouTube, a podcast app, system audio        | AirConnect                                    |
| Chromecast devices                                       | AirConnect (`aircast`)                        |
| Spotify on a Sonos                                       | Neither — Sonos does Spotify Connect natively |

Each speaker then appears twice in the Spotify picker: once as an AirPlay output
(`Living Room`) and once as a Spotify Connect device (`Living Room+`). The trailing `+`
is SpotConnect's upstream default (`-N "%s+"`) and is worth keeping for exactly this
reason. If you prefer something else, `SPOTUPNP_NAME_FORMAT` and `SPOTRAOP_NAME_FORMAT`
take any C format string with `%s` for the speaker's name.

**Ports.** Both packages run a UPnP stack and both would otherwise want the same default
port. This package ships defaults that stay out of AirConnect's way:

| Package                | UPnP port | HTTP/RTP range |
| ---------------------- | --------- | -------------- |
| AirConnect `airupnp`   | 49154     | 49155–49282    |
| SpotConnect `spotupnp` | 49300     | 49301–49428    |
| SpotConnect `spotraop` | —         | 49430–49557    |

Coexistence on one NAS has **not been verified on hardware yet**. The port separation is
deliberate rather than tested, and if you hit a conflict, `SPOTUPNP_PORT` is the knob.

## The honest limits

**Spotify Premium is probably required.** cspot, the library underneath, documents "Only
to be used with premium spotify accounts". SpotConnect itself says nothing about it. This
has not been tested with a free account, and until it has, treat it as likely but
unconfirmed.

**This is an unofficial integration.** SpotConnect talks to Spotify through a
reverse-engineered client. It is not endorsed by Spotify, it is not covered by any
guarantee from them, and a server-side change can break it at any time. Upstream has had
to react to exactly that before — the switch to an application client ID in 0.20.0 came
from Spotify closing off part of the Web API.

**The AirPlay device password is obfuscated, not encrypted.** `spotraop`'s `-L` option
stores an AirPlay speaker password in the config file as XOR plus Base64. That is
scrambling, not protection. Anyone who can read the file can recover it.

**Re-encoding costs CPU.** The NAS decodes Vorbis and re-encodes to whatever the speaker
takes. FLAC is upstream's recommendation and the most expensive; MP3 is much cheaper. How
much this matters on an older model has not been measured, so the shipped codec default
is provisional.

**No Chromecast.** Upstream ships `spotupnp` and `spotraop` only.

**Sound quality is not the reason to use this.** Both paths end up re-encoding a lossy
source once. If you use FLAC, the difference between bridging over AirPlay and bridging
over Spotify Connect is not something to expect to hear. The reason to use this is
control and independence from the phone.
