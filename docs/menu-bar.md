---
lang: en
ref: menu-bar
title: Menu bar app
permalink: /menu-bar/
---

Pulsar lives in the menu bar as a gauge icon. Click it to see the latest results.

## The menu

- **Download, upload, ping** and responsiveness or jitter from the last successful test, and how long ago it ran.
- **Last 24 hours** — a small chart of download and upload.
- **Next test** — when the next scheduled test runs. While a test runs, the icon changes and the menu says *Testing…*.
- **Run Test Now** starts a test right away.
- **Open Dashboard** opens the [dashboard]({{ '/dashboard/' | relative_url }}) in your browser.
- **History…** opens a window with a chart and a table of the last 30 days.
- **Settings…** opens the settings.

If the last test failed, the menu shows why in red.

## Settings

| Tab | What it sets |
|---|---|
| Testing | Engine, the Ookla license and server, how often to test, keeping the Mac awake, how long to keep history |
| Notifications | When to alert, Telegram, ntfy and the webhook, a test notification |
| Dashboard | Whether to serve it, its `.local` name and port |
| General | Language, launch at login |

## Language

Pulsar speaks English and Russian. By default it follows the macOS language; Settings → General → **Language** picks English or Russian for Pulsar alone. macOS applies an app's language at launch, so Settings offers to relaunch Pulsar.
