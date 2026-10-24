---
lang: ru
ref: api
title: HTTP API
permalink: /ru/api/
---

Сервер веб-панели отвечает на эти запросы по тому же адресу и порту, что и панель. Даты — в ISO 8601 по UTC, скорость — в Мбит/с, время — в миллисекундах. В качестве хоста нужно указывать `localhost`, имя `.local` или IP-адрес; на любой другой хост сервер отвечает `421`.

| Запрос | Возвращает |
|---|---|
| `GET /api/results?days=7` | Результаты в JSON, сначала новые, за 1–365 дней (по умолчанию 7) |
| `GET /api/results.csv?days=7` | То же в CSV |
| `GET /api/latest` | Последний удачный результат или `null` |
| `GET /api/status` | Идёт ли тест, когда следующий, движок и пороги |
| `GET /api/servers` | Ближайшие серверы Ookla; пусто при networkQuality |
| `POST /api/run?server=ID` | Запускает тест, при желании на конкретном сервере Ookla |
| `GET /metrics` | [Метрики Prometheus]({{ '/ru/prometheus/' | relative_url }}) |

## Результат

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

`engine` — `ookla` или `networkQuality`. У результатов networkQuality вместо джиттера, потерь и пинга под нагрузкой есть `responsivenessRPM`. У неудачного теста есть только `id`, `date`, `engine` и `error`. Поля без значения пропускаются.

## Статус

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

`paused` равно true, пока не принята лицензия Ookla. `serverID` — сервер для тестов по расписанию; его нет, если Pulsar выбирает ближайший.

## Запуск теста

`POST /api/run` требует заголовок `X-Pulsar-Run: 1`. Браузер отправляет его только со страницы самой панели, поэтому другие сайты не могут запускать тесты. Ответ: `202`, если тест начался, `409`, пока идёт другой тест или тесты на паузе, и `403` без заголовка.

```sh
curl -X POST -H 'X-Pulsar-Run: 1' http://pulsar.local:8765/api/run
curl -X POST -H 'X-Pulsar-Run: 1' 'http://pulsar.local:8765/api/run?server=1348'
```

## CSV

Колонки: `date`, `engine`, `download_mbps`, `upload_mbps`, `latency_ms`, `jitter_ms`, `download_latency_ms`, `upload_latency_ms`, `packet_loss_percent`, `responsiveness_rpm`, `interface`, `server`, `isp`, `result_url` и `error`.
