---
lang: en
ref: building
title: Building from source
permalink: /building/
---

Pulsar needs Xcode 16 or later.

```sh
git clone https://github.com/fosoaq/pulsar.git
cd pulsar
open Pulsar.xcodeproj
```

## Scripts

| Command | Does |
|---|---|
| `scripts/install.sh` | Builds a Release copy and installs it into `/Applications` |
| `scripts/release.sh [notes.md]` | Builds, zips and publishes a GitHub release for the current `MARKETING_VERSION` |
| `swift scripts/make-icon.swift` | Redraws the app icon in every size |
| `xcodebuild test -project Pulsar.xcodeproj -scheme Pulsar` | Runs the tests |

## Layout

| Folder | |
|---|---|
| `Pulsar/App` | The app, its model and settings |
| `Pulsar/SpeedTest` | The Ookla and networkQuality engines and the result type |
| `Pulsar/Storage` | The SQLite store |
| `Pulsar/Dashboard` | The web server, the dashboard page and its formats |
| `Pulsar/System` | Notifications, Bonjour, sleep, updates |
| `Pulsar/Views` | Menu, history and settings |
| `PulsarTests` | Tests, with anonymized real tool output in `Fixtures` |
| `docs` | This site, built by GitHub Pages with Jekyll |

Pulsar is written in Swift and SwiftUI, stores results with [GRDB](https://github.com/groue/GRDB.swift) and serves the dashboard with [Hummingbird](https://github.com/hummingbird-project/hummingbird).
