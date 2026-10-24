---
lang: ru
ref: building
title: Сборка из исходников
permalink: /ru/building/
---

Для сборки нужен Xcode 16 или новее.

```sh
git clone https://github.com/fosoaq/pulsar.git
cd pulsar
open Pulsar.xcodeproj
```

## Скрипты

| Команда | Что делает |
|---|---|
| `scripts/install.sh` | Собирает Release-версию и ставит её в `/Applications` |
| `scripts/release.sh [notes.md]` | Собирает, упаковывает и публикует релиз на GitHub для текущего `MARKETING_VERSION` |
| `swift scripts/make-icon.swift` | Перерисовывает иконку приложения во всех размерах |
| `xcodebuild test -project Pulsar.xcodeproj -scheme Pulsar` | Запускает тесты |

## Структура

| Папка | |
|---|---|
| `Pulsar/App` | Приложение, его модель и настройки |
| `Pulsar/SpeedTest` | Движки Ookla и networkQuality и тип результата |
| `Pulsar/Storage` | Хранилище SQLite |
| `Pulsar/Dashboard` | Веб-сервер, страница панели и форматы ответов |
| `Pulsar/System` | Уведомления, Bonjour, сон, обновления |
| `Pulsar/Views` | Меню, история и настройки |
| `PulsarTests` | Тесты, с обезличенными ответами настоящих утилит в `Fixtures` |
| `docs` | Этот сайт, его собирает GitHub Pages с помощью Jekyll |

Pulsar написан на Swift и SwiftUI, хранит результаты с помощью [GRDB](https://github.com/groue/GRDB.swift) и показывает веб-панель через [Hummingbird](https://github.com/hummingbird-project/hummingbird).
