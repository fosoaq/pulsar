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
| `POST /api/run?server=ID` | Starts a test, optionally on an Ookla server; needs the header `X-Pulsar-Run: 1` |
| `GET /api/servers` | Nearby Ookla servers |
| `GET /metrics` | Prometheus metrics for the last test |

Requests must use `localhost`, a `.local` name or an IP address as the host.

## Installing

Requires macOS 14 or later, on Apple silicon or Intel.

1. Download `Pulsar-<version>.zip` from [Releases](https://github.com/fosoaq/pulsar/releases),
   unzip it and move `Pulsar.app` to Applications.
2. Pulsar is not notarized by Apple, so the first launch is blocked. Open System Settings →
   Privacy & Security and click **Open Anyway**, or run
   `xattr -dr com.apple.quarantine /Applications/Pulsar.app` once.

Pulsar adds itself to login items on its first launch from Applications; Settings → General
turns that off. When a newer release appears, the menu shows a link to it.

## Building

Requires Xcode 16 or later.

```sh
scripts/install.sh            # build a Release copy and install it into /Applications
xcodebuild test -project Pulsar.xcodeproj -scheme Pulsar
```

`scripts/release.sh` publishes a GitHub release for the current `MARKETING_VERSION`, and
`swift scripts/make-icon.swift` redraws the app icon.
