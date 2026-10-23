---
title: FAQ
permalink: /faq/
---

## Does Pulsar test while the Mac sleeps?

No. macOS freezes apps during sleep, so neither tests nor the dashboard run then. Pulsar keeps the Mac from idle-sleeping while it runs, and the display still turns off; Settings → Testing turns that off. A laptop with the lid closed sleeps regardless. A Mac mini on Ethernet makes a good always-on monitor.

## Wi-Fi or Ethernet?

Over Wi-Fi the result shows the speed in that room as much as the speed of your plan. To measure the line itself, connect the Mac with a cable.

## Why do Ookla and networkQuality give different results?

They measure against different servers in different ways. Pulsar's averages and statistics use the engine of the latest test, so the two are not mixed.

## Why does download drop in the evening?

Many people are online then, and the provider's network gets busy. The **Download by hour of day** chart on the dashboard's Statistics tab shows whether your line slows down at the same time every day — useful evidence for a talk with the provider.

## The dashboard does not open on my phone

- Check that the phone is on the same network as the Mac.
- Try the IP address from Settings → Dashboard; some phones cannot open `.local` names.
- If macOS asked whether Pulsar may accept incoming connections and it was denied, allow it in System Settings → Network → Firewall → Options.

## Settings says the address is already used

Another device on the network announces the same `.local` name, maybe a second Mac running Pulsar. Pick another name.

## Can I change the dashboard's language?

It follows the browser's preferred language: English or Russian.
