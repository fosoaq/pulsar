---
title: Speed tests
permalink: /speed-tests/
---

Pulsar measures with one of two command-line tools. Pick one in Settings → Testing.

## Ookla Speedtest CLI

The same measurement as speedtest.net, against the nearest server or one you choose. It is the default when installed. Ookla's license does not allow bundling the CLI, so install it with [Homebrew](https://brew.sh):

```sh
brew install teamookla/speedtest/speedtest
```

### License

Ookla asks you to accept its license before the first test. Settings → Testing links to the EULA, terms of use and privacy policy; once you tick **I accept the Speedtest license**, Pulsar passes `--accept-license --accept-gdpr` to the CLI for you. Until then, Ookla tests are paused and the menu says so.

### Server

By default each test goes to the nearest server, which can change from test to test. To always use the same one, pick it under **Server** in Settings → Testing; the list comes from `speedtest --servers`. A test started from the dashboard can use another server once.

### What it measures

| Value | Meaning |
|---|---|
| Download, upload | Throughput in Mbps |
| Ping | Round trip to the server while the line is idle |
| Jitter | How much the ping varies |
| Ping during download, during upload | Round trip while the line is busy. A big jump over the idle ping means calls and games suffer when someone downloads. |
| Packet loss | Share of packets that did not arrive |

## Apple networkQuality

Built into macOS, nothing to install. It measures against Apple's CDN and reports download, upload, idle ping and **responsiveness** in round trips per minute (RPM) — the higher, the better the line copes under load. It has no jitter, packet loss or server choice.

## Schedule

Settings → Testing sets how often to test, from every 15 minutes to once a day. The next test is due one interval after the previous one. After a failure, for example while the internet is down, Pulsar tries again in five minutes.

Tests need the Mac to be awake. **Keep the Mac awake for scheduled tests** stops idle sleep while Pulsar runs; the display still turns off. See the [FAQ]({{ '/faq/' | relative_url }}) for more on sleep.
