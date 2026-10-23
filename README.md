# Pulsar

A macOS menu bar app that runs internet speed tests on a schedule, keeps the history and
serves a dashboard to your local network. Meant for a Mac that stays on, such as a Mac mini
on Ethernet.

- Lives in the menu bar: latest download, upload, latency and responsiveness, a 24-hour chart,
  "Run Test Now", history and settings.
- Two engines: macOS's built-in `networkQuality` (nothing to install) or the official
  [Ookla Speedtest CLI](https://www.speedtest.net/apps/cli)
  (`brew install teamookla/speedtest/speedtest`, then run
  `speedtest --accept-license --accept-gdpr` once).
- Scheduled tests every 15 minutes to 24 hours; keeps the Mac from idle-sleeping while it runs.
- Notifications when a test fails or speed drops below a threshold.
- Dashboard at `http://<your-mac>.local:8765` with a read-only JSON API:
  `GET /api/results?days=7`, `GET /api/latest`.
- History in SQLite at `~/Library/Application Support/Pulsar/pulsar.sqlite`.

## Building

Requires Xcode 16 or later and macOS 14 or later.

```sh
open Pulsar.xcodeproj
```

or from the command line:

```sh
xcodebuild -project Pulsar.xcodeproj -scheme Pulsar -configuration Release build
```
