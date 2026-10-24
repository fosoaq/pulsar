---
lang: ru
ref: prometheus
title: Prometheus
permalink: /ru/prometheus/
---

`GET /metrics` отдаёт последний удачный тест и то, прошёл ли последний тест, в текстовом формате Prometheus. Показатели без замера, например джиттер после теста networkQuality, пропускаются.

| Метрика | Что означает |
|---|---|
| `pulsar_download_mbps` | Скорость загрузки |
| `pulsar_upload_mbps` | Скорость отдачи |
| `pulsar_latency_ms` | Пинг в простое |
| `pulsar_jitter_ms` | Джиттер |
| `pulsar_download_latency_ms` | Пинг во время загрузки |
| `pulsar_upload_latency_ms` | Пинг во время отдачи |
| `pulsar_packet_loss_percent` | Потери пакетов |
| `pulsar_responsiveness_rpm` | Отзывчивость, только у networkQuality |
| `pulsar_last_success_timestamp_seconds` | Когда закончился последний удачный тест |
| `pulsar_last_test_timestamp_seconds` | Когда закончился последний тест |
| `pulsar_last_test_success` | 1, если последний тест прошёл, 0, если нет |

Все метрики — gauge.

## Настройка сбора

Указывайте IP-адрес Mac: Prometheus в Docker или на Linux часто не умеет открывать имена `.local`.

```yaml
scrape_configs:
  - job_name: pulsar
    scrape_interval: 5m
    static_configs:
      - targets: ["192.168.1.20:8765"]
```

Собирать чаще, чем Pulsar проводит тесты, бессмысленно: значения будут повторяться.

## Правила оповещений

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
