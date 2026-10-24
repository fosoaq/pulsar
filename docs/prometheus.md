---
lang: en
ref: prometheus
title: Prometheus
permalink: /prometheus/
---

`GET /metrics` serves the last successful test, and whether the latest one worked, in the Prometheus text format. Values without a measurement, such as jitter after a networkQuality test, are left out.

| Metric | Meaning |
|---|---|
| `pulsar_download_mbps` | Download speed |
| `pulsar_upload_mbps` | Upload speed |
| `pulsar_latency_ms` | Idle ping |
| `pulsar_jitter_ms` | Jitter |
| `pulsar_download_latency_ms` | Ping during the download |
| `pulsar_upload_latency_ms` | Ping during the upload |
| `pulsar_packet_loss_percent` | Packet loss |
| `pulsar_responsiveness_rpm` | Responsiveness, networkQuality only |
| `pulsar_last_success_timestamp_seconds` | When the last successful test finished |
| `pulsar_last_test_timestamp_seconds` | When the latest test finished |
| `pulsar_last_test_success` | 1 if the latest test succeeded, 0 if it failed |

All metrics are gauges.

## Scrape config

Use the Mac's IP address, since Prometheus in Docker or on Linux often cannot resolve `.local` names:

```yaml
scrape_configs:
  - job_name: pulsar
    scrape_interval: 5m
    static_configs:
      - targets: ["192.168.1.20:8765"]
```

Scraping more often than Pulsar tests only repeats the same values.

## Alert rule

```yaml
groups:
  - name: pulsar
    rules:
      - alert: InternetSpeedTestFailing
        expr: pulsar_last_test_success == 0
        for: 30m
      - alert: InternetSlow
        expr: pulsar_download_mbps < 300
        for: 2h
```
