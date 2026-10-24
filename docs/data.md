---
lang: en
ref: data
title: Data and privacy
permalink: /data/
---

## Where data lives

| What | Where |
|---|---|
| Test history | `~/Library/Application Support/Pulsar/pulsar.sqlite` |
| Settings | `~/Library/Preferences/io.github.fosoaq.Pulsar.plist` |

The history is a SQLite database with one `result` table, so any SQLite tool can read it. Pulsar keeps a year of history by default; Settings → Testing → **Keep history for** changes that, down to 30 days or up to forever.

## What leaves the Mac

- **Speed tests.** Each test talks to a speed test server. The Ookla CLI also reports results to Ookla, as speedtest.net does; networkQuality talks to Apple.
- **Notifications** go only to the channels you set up: Telegram, ntfy or your webhook.
- **Update check.** Once a day Pulsar asks GitHub for the latest release. Nothing about you or your results is sent.

Pulsar has no analytics and no account.

## On your network

The dashboard and API are open to every device on your local network, read-only except for starting a test. See [Dashboard access]({{ '/dashboard/' | relative_url }}#access). The Telegram bot token is stored in Pulsar's settings file, which only your macOS user can read.
