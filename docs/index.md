---
lang: en
ref: intro
title: Introduction
permalink: /
hide_title: true
---

<div class="hero">
  <img src="{{ '/images/icon.png' | relative_url }}" alt="">
  <h1>Pulsar</h1>
</div>

<p class="lead">An internet speed monitor that lives in the macOS menu bar. It runs speed tests on a schedule, keeps the history and serves a dashboard to every device on your local network.</p>

<div class="cta">
  <a class="button" href="https://github.com/fosoaq/pulsar/releases/latest">Download for macOS</a>
  <a href="{{ '/installation/' | relative_url }}">Installation guide</a>
  <span class="note">macOS 14 or later · Apple silicon and Intel · free</span>
</div>

<img class="shot" src="{{ '/images/dashboard-overview.jpg' | relative_url }}" alt="Pulsar dashboard: download, upload, ping and jitter, and a chart of the last seven days" width="1100" height="779">
<p class="caption">The dashboard, open from any device on the network. The data in the screenshots is made up.</p>

## What it does

<div class="features">
  <div><h3>Menu bar first</h3><p>Latest download, upload and ping, a 24-hour chart and a button to test now, one click away.</p></div>
  <div><h3>Scheduled tests</h3><p>Every 15 minutes to once a day, with a retry five minutes after a failure. The Mac stays awake for them.</p></div>
  <div><h3>Ping under load</h3><p>Besides idle ping and jitter, Pulsar records ping during the download and upload, which shows how the line copes when it is busy.</p></div>
  <div><h3>LAN dashboard</h3><p>Overview, full results and statistics at <code>http://pulsar.local</code>, with no account and no cloud.</p></div>
  <div><h3>Alerts</h3><p>Notification Center, Telegram and ntfy when a test fails or speed drops below a threshold. A webhook gets every result.</p></div>
  <div><h3>Your data</h3><p>Results stay in a SQLite file on your Mac. Export CSV, read the JSON API or scrape Prometheus metrics.</p></div>
</div>

## Who it is for

Pulsar suits a Mac that stays on, such as a Mac mini on Ethernet, watching the line around the clock. It is the same idea as [speedtest-tracker](https://github.com/alexjustesen/speedtest-tracker), but as a native app: no Docker, no server, one download.
