---
lang: en
ref: notifications
title: Notifications
permalink: /notifications/
---

Settings → Notifications sets when Pulsar alerts you:

- **When a test fails**, for example when the internet is down.
- **When download or upload is below** a speed in Mbps. 0 turns that threshold off.

Alerts always appear in Notification Center on the Mac. Each channel below turns on once its fields are filled. **Send Test Notification** checks them all and shows any channel that failed.

## Telegram

1. Create a bot with [@BotFather](https://t.me/BotFather) and copy its token.
2. Send the bot any message, so it may write to you.
3. Get your chat ID from [@userinfobot](https://t.me/userinfobot).
4. Paste the token and chat ID into Settings.

## ntfy

Enter a topic URL such as `https://ntfy.sh/my-pulsar` and subscribe to the same topic in the [ntfy](https://ntfy.sh) app on your phone. A self-hosted ntfy server works too. Anyone who knows a topic on ntfy.sh can read it, so pick a name that is hard to guess.

## Webhook

Pulsar sends a `POST` with JSON to the URL after every test, with an `alert` when one applies. This suits Home Assistant, n8n and similar tools.

| Field | |
|---|---|
| `event` | `test.completed`, `test.failed`, or `test.notification` for the test button |
| `alert` | `title` and `body`, only when the result triggers an alert |
| `result` | The test, as in the [HTTP API]({{ '/api/' | relative_url }}); fields without a value are left out |

```json
{
  "event": "test.completed",
  "alert": { "title": "Slow connection", "body": "Download 412 Mbps, below 800" },
  "result": {
    "id": 1042,
    "date": "2026-10-24T18:00:12Z",
    "engine": "ookla",
    "downloadMbps": 412.3,
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
}
```

A response outside 200–299 counts as a failure and shows in Settings.
