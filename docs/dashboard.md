---
lang: en
ref: dashboard
title: Dashboard
permalink: /dashboard/
---

Pulsar serves a dashboard to your local network, so you can check the line from a phone or another computer.

## Address

By default the dashboard is at `http://pulsar.local:8765`. Settings → Dashboard changes:

- **Address** — the name before `.local`. Pulsar announces it on the network over Bonjour, separately from the Mac's own name. If another device already uses the name, Settings says so.
- **Port** — with port 80 the address is just `http://pulsar.local`.

Some devices, mostly older Android phones, cannot open `.local` names. Settings also shows the address by IP for them.

## Tabs

- **Overview** — the latest download, upload, ping and jitter with their averages, a chart that switches between speed and ping, and the most recent tests.
- **Results** — every test with ping under load, packet loss, server and engine. Filter to failures only, or download the range as CSV.
- **Statistics** — the number of tests, success rate, tests below your alert threshold, the slowest hour, average, median and range of each value, download by hour of day and averages per server.

The range buttons — 24 hours, 7, 30 or 90 days — apply to every tab. **Run test** starts a test, on the server chosen next to it when Ookla is the engine; **Nearest server** lets Ookla pick.

The footer switches the theme (auto, light or dark) and the language (auto, English or Russian). Auto follows the device; the choice is remembered in that browser.

<img class="shot" src="{{ '/images/dashboard-statistics.jpg' | relative_url }}" alt="Statistics tab: success rate, tests below threshold, slowest hour, summary table and download by hour of day" width="1100" height="779" loading="lazy">
<p class="caption">Statistics. The slowest hour is marked only when it is clearly slower than the rest.</p>

## Access

The dashboard has no login: anyone on your network can open it and start a test, but cannot change settings. It answers only to `localhost`, `.local` names and IP addresses, which keeps web pages elsewhere from reading it through DNS rebinding, and starting a test needs a header other sites cannot send.

To keep it to this Mac alone, turn it off in Settings → Dashboard.
