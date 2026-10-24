---
lang: en
ref: installation
title: Installation
permalink: /installation/
---

Pulsar runs on macOS 14 Sonoma or later, on Apple silicon and Intel Macs.

## Install

1. Download `Pulsar-<version>.zip` from [the latest release](https://github.com/fosoaq/pulsar/releases/latest).
2. Unzip it and move `Pulsar.app` to Applications.
3. Open Pulsar. It appears in the menu bar, not in the Dock.

## Open an app that is not notarized

Pulsar is not notarized by Apple, so macOS blocks the first launch with a warning. Either:

- open System Settings → Privacy & Security, scroll to the message about Pulsar and click **Open Anyway**, or
- run once in Terminal:

```sh
xattr -dr com.apple.quarantine /Applications/Pulsar.app
```

## First launch

- Pulsar asks to send notifications. Allow it to get alerts about failed or slow tests.
- macOS may ask whether Pulsar can accept incoming network connections. Allow it, or other devices cannot open the dashboard.
- Pulsar adds itself to login items on its first launch from Applications. Settings → General turns that off.
- If the Ookla Speedtest CLI is installed, Pulsar uses it and first asks you to accept Ookla's license; otherwise it starts with the built-in networkQuality. See [Speed tests]({{ '/speed-tests/' | relative_url }}).

## Updates

Pulsar checks GitHub for a new release once a day. When there is one, the menu shows a link to it; download it and replace the app in Applications. Settings and history are kept.

## Uninstall

1. Quit Pulsar from its menu.
2. Delete `Pulsar.app` from Applications.
3. To remove the history and settings too:

```sh
rm -rf ~/Library/Application\ Support/Pulsar
defaults delete io.github.fosoaq.Pulsar
```
