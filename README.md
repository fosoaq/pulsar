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
- Notifications when a test fails or speed drops below a threshold: Notification Center,
  Telegram and ntfy; a webhook receives every result as JSON.
- Dashboard at `http://pulsar.local:8765` (the name and port are configurable; port 80 drops
  it from the address) with a "Run test" button and CSV export.
- History in SQLite at `~/Library/Application Support/Pulsar/pulsar.sqlite`, kept for a year by
  default.

## HTTP API

| Endpoint | |
|---|---|
| `GET /api/results?days=7` | Results as JSON, newest first (1–365 days) |
| `GET /api/results.csv?days=7` | The same as CSV |
| `GET /api/latest` | The last successful result |
| `GET /api/status` | Whether a test is running and when the next one is due |
| `POST /api/run` | Starts a test; needs the header `X-Pulsar-Run: 1` |
| `GET /metrics` | Prometheus metrics for the last test |

Requests must use `localhost`, a `.local` name or an IP address as the host.

## Building

Requires Xcode 16 or later and macOS 14 or later.

```sh
open Pulsar.xcodeproj
```

or from the command line:

```sh
xcodebuild -project Pulsar.xcodeproj -scheme Pulsar -configuration Release build
```
