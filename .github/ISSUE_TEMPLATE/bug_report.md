---
name: Bug report
about: Something in the package does not work
title: ""
labels: bug
assignees: eizedev
---

## What happens

<!-- What did you expect, and what happened instead? -->

## Steps to reproduce

## Hardware

- Synology NAS or Router model: `[e.g. DS923+, RT2600ac]`
- DSM/SRM version: `[e.g. DSM 7.4.1-90080]`

## Package

- Which `.spk` you installed: `[e.g. SpotConnect-dsm7-x86_64-0.20.8-20260917.spk]`
- Did you use the `-static` variant? `[yes/no]`

## Speaker

- Make and model: `[e.g. Denon AVR-X2000, AirPort Express 2nd gen]`
- Bridge it uses: `[spotupnp (UPnP/DLNA) / spotraop (AirPlay)]`
- Does the speaker work from the Spotify desktop app directly, if it can do that at all?

## Log

<!--
Set SPOTUPNP_LOGLEVEL="all=debug" (or SPOTRAOP_LOGLEVEL) in
/var/packages/SpotConnect/target/spotconnect.conf, restart the package, reproduce,
then attach the relevant part of `synopkg log SpotConnect`.

Please check the log for anything you would rather not publish before pasting it.
-->

## Anything else

<!--
Before filing: problems with playback behaviour, protocol handling or a specific
speaker's quirks usually belong upstream at
https://github.com/philippe44/SpotConnect/issues - this repository packages
SpotConnect, it does not write it. Installing, starting, stopping, configuring
and upgrading the package are the right things to report here. If you are not
sure, report it here anyway and it will be routed.
-->
