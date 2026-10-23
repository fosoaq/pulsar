---
title: HTTP API
permalink: /api/
---

The dashboard server answers these requests on the same address and port as the dashboard. Dates are ISO 8601 in UTC, speeds in Mbps and times in milliseconds. Requests must use `localhost`, a `.local` name or an IP address as the host; any other host gets `421`.

| Request | Returns |
|---|---|
| `GET /api/results?days=7` | Results as JSON, newest first, for 1 to 365 days (7 by default) |
| `GET /api/results.csv?days=7` | The same as CSV |
| `GET /api/latest` | The last successful result, or `null` |
| `GET /api/status` | Whether a test is running, when the next one is due, the engine and thresholds |
| `GET /api/servers` | Nearby Ookla servers; empty with networkQuality |
| `POST /api/run?server=ID` | Starts a test, optionally on an Ookla server |
| `GET /metrics` | [Prometheus metrics]({{ '/prometheus/' | relative_url }}) |

## Result

```json
{
  "id": 1042,
  "date": "2026-10-24T18:00:12Z",
  "engine": "ookla",
  "downloadMbps": 912.4,
  "uploadMbps": 458.1,
  "latencyMs": 3.6,
  "jitterMs": 0.4,
  "downloadLatencyMs": 14.2,
  "uploadLatencyMs": 19.8,
  "packetLossPercent": 0,
  "interfaceName": "en0",
  "server": "Example Fiber, Springfield",
  "isp": "Example ISP",
  "resultURL": "https://www.speedtest.net/result/c/…"
}
```

`engine` is `ookla` or `networkQuality`. networkQuality results carry `responsivenessRPM` instead of jitter, packet loss and ping under load. A failed test has only `id`, `date`, `engine` and `error`. Fields without a value are left out.

## Status

```json
{
  "running": false,
  "paused": false,
  "nextRun": "2026-10-24T19:00:12Z",
  "engine": "ookla",
  "serverID": 1348,
  "minDownloadMbps": 800,
  "minUploadMbps": 0,
  "hostName": "Mac mini",
  "version": "0.1.0"
}
```

`paused` is true while Ookla's license is not accepted. `serverID` is the server scheduled tests use, absent when Pulsar picks the nearest.

## Starting a test

`POST /api/run` needs the header `X-Pulsar-Run: 1`. Browsers send it only from the dashboard itself, which keeps other web pages from starting tests. It answers `202` when the test starts, `409` while one is running or tests are paused, and `403` without the header.

```sh
curl -X POST -H 'X-Pulsar-Run: 1' http://pulsar.local:8765/api/run
curl -X POST -H 'X-Pulsar-Run: 1' 'http://pulsar.local:8765/api/run?server=1348'
```

## CSV

The columns are `date`, `engine`, `download_mbps`, `upload_mbps`, `latency_ms`, `jitter_ms`, `download_latency_ms`, `upload_latency_ms`, `packet_loss_percent`, `responsiveness_rpm`, `interface`, `server`, `isp`, `result_url` and `error`.
