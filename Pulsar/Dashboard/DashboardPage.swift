/// The LAN dashboard: one self-contained page, no external requests, so it works without internet.
enum DashboardPage {
    static let html = #"""
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Pulsar</title>
    <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='14' fill='%23312e81'/%3E%3Cpath d='M14 44a20 20 0 1 1 36 0' fill='none' stroke='%2367e8f9' stroke-width='6' stroke-linecap='round'/%3E%3Cpath d='M32 40 44 26' stroke='white' stroke-width='5' stroke-linecap='round'/%3E%3C/svg%3E">
    <style>
    :root{--bg:#f5f6f8;--card:#fff;--text:#16181d;--muted:#6b7280;--line:#e4e7ec;--grid:#eef0f3;--down:#2563eb;--up:#ea580c;--lat:#7c3aed;--jit:#0d9488;--bad:#dc2626;--ok:#16a34a;color-scheme:light}
    @media (prefers-color-scheme:dark){:root{--bg:#0f1115;--card:#171a21;--text:#e8eaf0;--muted:#9aa3b2;--line:#2a2f3a;--grid:#21252e;--down:#60a5fa;--up:#fb923c;--lat:#a78bfa;--jit:#2dd4bf;--bad:#f87171;--ok:#4ade80;color-scheme:dark}}
    *{box-sizing:border-box}
    body{margin:0;background:var(--bg);color:var(--text);font:15px/1.45 -apple-system,BlinkMacSystemFont,"Segoe UI",system-ui,sans-serif}
    main{max-width:1080px;margin:0 auto;padding:24px 16px 48px}
    header{display:flex;flex-wrap:wrap;gap:12px;align-items:center;justify-content:space-between;margin-bottom:20px}
    h1{font-size:22px;margin:0;display:flex;flex-wrap:wrap;align-items:center;gap:10px}
    .pill{display:inline-flex;align-items:center;gap:6px;font-size:12px;font-weight:500;color:var(--muted);background:var(--card);border:1px solid var(--line);border-radius:999px;padding:3px 10px}
    .pill .dot{width:7px;height:7px;border-radius:50%;background:var(--ok)}
    .pill.running .dot{background:var(--down);animation:pulse 1s ease-in-out infinite}
    .pill.paused .dot{background:var(--muted)}
    @keyframes pulse{50%{opacity:.25}}
    .sub{color:var(--muted);font-size:13px;margin-top:2px}
    .controls{display:flex;flex-wrap:wrap;gap:8px;align-items:center}
    .btn{border:1px solid var(--line);background:var(--card);color:var(--text);padding:7px 14px;border-radius:10px;font:inherit;font-size:13px;cursor:pointer;text-decoration:none}
    .btn.primary{background:var(--down);border-color:var(--down);color:#fff}
    .btn:disabled{opacity:.55;cursor:default}
    .seg{display:flex;gap:4px;background:var(--card);border:1px solid var(--line);border-radius:10px;padding:3px}
    .seg button{border:0;background:none;color:var(--text);padding:5px 11px;border-radius:7px;font:inherit;font-size:13px;cursor:pointer}
    .seg button[aria-pressed=true]{background:var(--down);color:#fff}
    .tiles{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:12px;margin-bottom:16px}
    .card{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:16px}
    .tile .label{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.04em}
    .tile .value{font-size:28px;font-weight:650;font-variant-numeric:tabular-nums;margin-top:4px;white-space:nowrap}
    .tile .value small{font-size:14px;color:var(--muted);font-weight:500;margin-left:4px}
    .tile .value.small{font-size:18px;line-height:42px}
    .tile .hint{color:var(--muted);font-size:12px;margin-top:2px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
    .chart{margin-bottom:16px;position:relative}
    .chart-head{display:flex;flex-wrap:wrap;gap:12px;align-items:center;justify-content:space-between;margin-bottom:8px}
    .legend{display:flex;gap:16px;font-size:13px;color:var(--muted)}
    .legend i{display:inline-block;width:10px;height:10px;border-radius:3px;margin-right:6px;vertical-align:-1px}
    svg{display:block;width:100%;height:280px;touch-action:pan-y}
    svg text{fill:var(--muted);font-size:11px}
    .tip{position:absolute;pointer-events:none;background:var(--card);border:1px solid var(--line);border-radius:10px;padding:8px 10px;font-size:12px;box-shadow:0 6px 20px rgba(0,0,0,.18);white-space:nowrap;display:none;z-index:2}
    .tip b{font-variant-numeric:tabular-nums}
    .tip .row{display:flex;align-items:center;gap:6px}
    .tip i{display:inline-block;width:8px;height:8px;border-radius:2px}
    .table-head{display:flex;flex-wrap:wrap;gap:12px;align-items:center;justify-content:space-between;margin-bottom:8px}
    .table-head h2{font-size:15px;margin:0}
    .check{font-size:13px;color:var(--muted);display:flex;gap:6px;align-items:center;cursor:pointer}
    .table-wrap{overflow-x:auto}
    table{width:100%;border-collapse:collapse;font-size:14px;font-variant-numeric:tabular-nums}
    th,td{text-align:left;padding:8px 10px;border-bottom:1px solid var(--line);white-space:nowrap}
    th{color:var(--muted);font-weight:500;font-size:12px;text-transform:uppercase}
    td.err,td.wrap{white-space:normal;min-width:160px;max-width:280px}
    td.err{color:var(--bad)}
    td a{color:inherit}
    .empty{color:var(--muted);padding:32px;text-align:center}
    .more{display:block;margin:12px auto 0}
    footer{color:var(--muted);font-size:12px;margin-top:20px;text-align:center}
    footer a{color:inherit}
    </style>
    </head>
    <body>
    <main>
    <header>
      <div>
        <h1>Pulsar <span class="pill" id="pill"><span class="dot"></span><span id="pill-text"></span></span></h1>
        <div class="sub" id="updated" data-i18n>Loading…</div>
      </div>
      <div class="controls">
        <button class="btn primary" id="run" data-i18n>Run test</button>
        <a class="btn" id="csv" href="/api/results.csv?days=7">CSV</a>
        <div class="seg" id="ranges"></div>
      </div>
    </header>

    <section class="tiles" id="tiles"></section>

    <section class="card chart">
      <div class="chart-head">
        <div class="legend" id="legend"></div>
        <div class="seg" id="metrics"></div>
      </div>
      <svg id="chart" role="img" aria-label="Speed test results over time"></svg>
      <div class="tip" id="tip"></div>
    </section>

    <section class="card">
      <div class="table-head">
        <h2 data-i18n>History</h2>
        <label class="check"><input type="checkbox" id="failures-only"> <span data-i18n>Failures only</span></label>
      </div>
      <div class="table-wrap">
        <table>
          <thead><tr><th data-i18n>Time</th><th data-i18n>Download</th><th data-i18n>Upload</th><th data-i18n>Latency</th><th data-i18n>Jitter</th><th data-i18n>Loss</th><th data-i18n>Server</th><th data-i18n>Engine</th><th data-i18n>Status</th></tr></thead>
          <tbody id="rows"></tbody>
        </table>
      </div>
      <button class="btn more" id="more" hidden data-i18n>Show more</button>
    </section>

    <footer><a href="/api/results">JSON</a> · <a href="/metrics">Prometheus</a> · <a href="https://github.com/fosoaq/pulsar">GitHub</a></footer>
    </main>
    <script>
    // Russian when the browser prefers it; English otherwise.
    const RU = {
      "Loading…": "Загрузка…", "Run test": "Запустить тест", "Testing…": "Идёт тест…",
      "Download": "Загрузка", "Upload": "Отдача", "Latency": "Задержка", "Jitter": "Джиттер", "Loss": "Потери",
      "Server": "Сервер", "Status": "Статус", "Time": "Время", "Engine": "Движок",
      "Last test": "Последний тест", "Success rate": "Успешных", "avg": "в среднем",
      "of": "из", "tests": "тестов", "Mbps": "Мбит/с", "ms": "мс", "No data": "Нет данных",
      "No tests in this range yet.": "За этот период тестов нет.", "Updated": "Обновлено",
      "Next test": "Следующий тест в", "Tests paused": "Тесты на паузе",
      "Could not load results": "Не удалось загрузить результаты",
      "Accept the Speedtest license in Pulsar's settings first": "Сначала примите лицензию Speedtest в настройках Pulsar",
      "24h": "24ч", "7d": "7д", "30d": "30д", "90d": "90д", "Speed": "Скорость",
      "History": "История", "Failures only": "Только ошибки", "Show more": "Показать ещё",
      "min": "мин", "max": "макс", "minutes ago": "мин назад", "just now": "только что",
    };
    const L10N = /^ru\b/i.test((navigator.languages || [])[0] || navigator.language || "") ? RU : {};
    const t = s => L10N[s] || s;
    if (L10N === RU) document.documentElement.lang = "ru";
    document.querySelectorAll("[data-i18n]").forEach(el => { el.textContent = t(el.textContent) });

    const RANGES = [["24h", 1], ["7d", 7], ["30d", 30], ["90d", 90]];
    const METRICS = {
      speed: {label: "Speed", unit: "Mbps", series: [["downloadMbps", "Download", "--down"], ["uploadMbps", "Upload", "--up"]]},
      latency: {label: "Latency", unit: "ms", series: [["latencyMs", "Latency", "--lat"], ["jitterMs", "Jitter", "--jit"]]},
    };
    const ENGINES = {ookla: "Ookla", networkQuality: "networkQuality"};
    const PAGE = 50;

    const prefs = {
      get(key, fallback) { try { return localStorage.getItem(key) ?? fallback } catch (e) { return fallback } },
      set(key, value) { try { localStorage.setItem(key, value) } catch (e) {} },
    };
    let days = Number(prefs.get("days", 7)) || 7;
    let metric = METRICS[prefs.get("metric", "speed")] ? prefs.get("metric", "speed") : "speed";
    let shown = PAGE;
    let data = [];

    const $ = id => document.getElementById(id);
    const esc = s => String(s).replace(/[&<>"']/g, c => ({"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"}[c]));
    const num = v => v == null ? "—" : v >= 100 ? v.toFixed(0) : String(+v.toFixed(v >= 10 ? 1 : 2));
    const ms = v => v == null ? "—" : `${num(v)} ${t("ms")}`;
    const fmtTime = d => d.toLocaleString([], {month: "short", day: "numeric", hour: "2-digit", minute: "2-digit"});
    const fmtClock = d => d.toLocaleTimeString([], {hour: "2-digit", minute: "2-digit"});
    const avg = xs => { xs = xs.filter(v => v != null); return xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : null };
    const ago = d => {
      const minutes = Math.round((Date.now() - d) / 60000);
      if (minutes < 1) return t("just now");
      if (minutes < 60) return `${minutes} ${t("minutes ago")}`;
      return fmtTime(d);
    };

    function renderSegments() {
      $("ranges").innerHTML = RANGES.map(([label, d]) => `<button aria-pressed="${d === days}" data-days="${d}">${t(label)}</button>`).join("");
      $("metrics").innerHTML = Object.entries(METRICS).map(([key, m]) => `<button aria-pressed="${key === metric}" data-metric="${key}">${t(m.label)}</button>`).join("");
      $("legend").innerHTML = METRICS[metric].series.map(([, label, color]) => `<span><i style="background:var(${color})"></i>${t(label)}</span>`).join("");
    }

    $("ranges").addEventListener("click", e => {
      const button = e.target.closest("button");
      if (!button) return;
      days = Number(button.dataset.days);
      prefs.set("days", days);
      shown = PAGE;
      renderSegments();
      load();
    });

    $("metrics").addEventListener("click", e => {
      const button = e.target.closest("button");
      if (!button) return;
      metric = button.dataset.metric;
      prefs.set("metric", metric);
      renderSegments();
      drawChart();
    });

    $("failures-only").addEventListener("change", () => { shown = PAGE; renderRows() });
    $("more").addEventListener("click", () => { shown += PAGE; renderRows() });

    let wasRunning = false;
    async function refreshStatus() {
      try {
        const status = await (await fetch("/api/status")).json();
        const button = $("run");
        button.disabled = status.running || status.paused;
        button.textContent = t(status.running ? "Testing…" : "Run test");
        button.title = status.paused ? t("Accept the Speedtest license in Pulsar's settings first") : "";
        $("pill").className = "pill" + (status.running ? " running" : status.paused ? " paused" : "");
        $("pill-text").textContent = status.running ? t("Testing…") : status.paused ? t("Tests paused") : `${t("Next test")} ${fmtClock(new Date(status.nextRun))}`;
        if (wasRunning && !status.running) load();
        wasRunning = status.running;
        if (status.running) setTimeout(refreshStatus, 3000);
      } catch (e) {}
    }

    $("run").addEventListener("click", async () => {
      $("run").disabled = true;
      await fetch("/api/run", {method: "POST", headers: {"X-Pulsar-Run": "1"}});
      refreshStatus();
    });

    async function load() {
      try {
        const response = await fetch(`/api/results?days=${days}`);
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        data = (await response.json()).map(r => ({...r, date: new Date(r.date)}));
        $("csv").href = `/api/results.csv?days=${days}`;
        $("updated").textContent = `${t("Updated")} ${fmtClock(new Date())}`;
        render();
      } catch (e) {
        $("updated").textContent = `${t("Could not load results")}: ${e.message}`;
      }
    }

    function render() {
      const ok = data.filter(r => !r.error);
      const last = ok[0];
      // Statistics use the engine of the latest result: the two engines measure against different servers.
      const same = ok.filter(r => r.engine === last?.engine);
      const spread = values => {
        values = values.filter(v => v != null);
        return values.length > 1 ? `${t("min")} ${num(Math.min(...values))} · ${t("max")} ${num(Math.max(...values))}` : "";
      };
      const stats = key => [`${t("avg")} ${num(avg(same.map(r => r[key])))}`, spread(same.map(r => r[key]))].filter(Boolean).join(" · ");
      const tile = (label, value, unit, hint, extra = "") =>
        `<div class="card tile"><div class="label">${label}</div><div class="value ${extra}">${value}${unit ? `<small>${unit}</small>` : ""}</div><div class="hint" title="${hint}">${hint}</div></div>`;
      const rate = data.length ? Math.round(ok.length / data.length * 100) : null;
      $("tiles").innerHTML = [
        tile(t("Download"), num(last?.downloadMbps), t("Mbps"), stats("downloadMbps")),
        tile(t("Upload"), num(last?.uploadMbps), t("Mbps"), stats("uploadMbps")),
        tile(t("Latency"), num(last?.latencyMs), t("ms"), last?.jitterMs != null ? `${t("Jitter")} ${ms(last.jitterMs)}` : stats("latencyMs")),
        tile(t("Last test"), last ? esc(ago(last.date)) : "—", "", last ? esc([ENGINES[last.engine] || last.engine, last.server].filter(Boolean).join(" · ")) : "", "small"),
        tile(t("Success rate"), rate == null ? "—" : `${rate}%`, "", `${ok.length} ${t("of")} ${data.length} ${t("tests")}`),
      ].join("");
      drawChart();
      renderRows();
    }

    function renderRows() {
      const rows = $("failures-only").checked ? data.filter(r => r.error) : data;
      $("rows").innerHTML = rows.length
        ? rows.slice(0, shown).map(r => `<tr>
            <td>${r.resultURL ? `<a href="${esc(r.resultURL)}" target="_blank" rel="noopener">${fmtTime(r.date)}</a>` : fmtTime(r.date)}</td>
            <td>${num(r.downloadMbps)}</td>
            <td>${num(r.uploadMbps)}</td>
            <td>${ms(r.latencyMs)}</td>
            <td>${ms(r.jitterMs)}</td>
            <td>${r.packetLossPercent != null ? num(r.packetLossPercent) + "%" : "—"}</td>
            <td class="wrap">${r.server ? esc(r.server) : "—"}</td>
            <td>${esc(ENGINES[r.engine] || r.engine)}</td>
            ${r.error ? `<td class="err">${esc(r.error)}</td>` : "<td>OK</td>"}
          </tr>`).join("")
        : `<tr><td colspan="9" class="empty">${t("No tests in this range yet.")}</td></tr>`;
      $("more").hidden = rows.length <= shown;
    }

    // The time axis spans the data rather than the whole range, so a few tests from
    // the last hour do not collapse into one spot at the right edge of a week.
    let geometry = null;

    function niceMax(value) {
      if (value <= 0) return 1;
      const step = Math.pow(10, Math.floor(Math.log10(value)));
      return [1, 2, 2.5, 5, 10].map(m => m * step).find(v => v >= value);
    }

    function timeTicks(t0, t1, count) {
      const steps = [5, 10, 15, 30, 60, 120, 180, 360, 720, 1440, 2880, 10080].map(m => m * 60000);
      const step = steps.find(s => (t1 - t0) / s <= count) || steps[steps.length - 1];
      // Align ticks to local time, so they land on whole hours and midnights.
      const offset = new Date(t0).getTimezoneOffset() * 60000;
      const ticks = [];
      for (let tick = Math.ceil((t0 - offset) / step) * step + offset; tick <= t1; tick += step) ticks.push(tick);
      return {ticks, daily: step >= 86400000};
    }

    function drawChart() {
      const svg = $("chart");
      const config = METRICS[metric];
      const points = data.filter(r => !r.error).slice().reverse();
      const W = svg.clientWidth || 800, H = 280, L = 48, R = 16, T = 16, B = 28;
      svg.setAttribute("viewBox", `0 0 ${W} ${H}`);
      geometry = null;
      $("tip").style.display = "none";
      if (!points.length) {
        svg.innerHTML = `<text x="${W / 2}" y="${H / 2}" text-anchor="middle">${t("No data")}</text>`;
        return;
      }

      const first = +points[0].date, last = +points[points.length - 1].date;
      const span = Math.max(last - first, 30 * 60000);
      const t0 = Math.max(Date.now() - days * 864e5, first - span * 0.04);
      const t1 = last + span * 0.04;
      const values = points.flatMap(p => config.series.map(([key]) => p[key])).filter(v => v != null);
      const max = niceMax(Math.max(...values, 0) * 1.05);
      const x = time => L + (time - t0) / (t1 - t0) * (W - L - R);
      const y = v => T + (1 - v / max) * (H - T - B);

      let out = "<defs>" + config.series.map(([key, , color]) =>
        `<linearGradient id="fill-${key}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" style="stop-color:var(${color});stop-opacity:.16"/><stop offset="1" style="stop-color:var(${color});stop-opacity:0"/></linearGradient>`).join("") + "</defs>";
      for (let i = 0; i <= 4; i++) {
        const v = max * i / 4, yy = y(v);
        out += `<line x1="${L}" x2="${W - R}" y1="${yy}" y2="${yy}" style="stroke:var(--grid)"/>`;
        out += `<text x="${L - 8}" y="${yy + 4}" text-anchor="end">${num(v)}</text>`;
      }
      const {ticks, daily} = timeTicks(t0, t1, Math.max(3, Math.floor((W - L - R) / 90)));
      for (const tick of ticks) {
        const d = new Date(tick);
        const midnight = d.getHours() === 0 && d.getMinutes() === 0;
        const label = daily || midnight ? d.toLocaleDateString([], {month: "short", day: "numeric"}) : fmtClock(d);
        out += `<text x="${x(tick)}" y="${H - 8}" text-anchor="middle">${label}</text>`;
      }
      out += `<text x="${L - 8}" y="${T - 6}" text-anchor="end" style="font-size:10px">${t(config.unit)}</text>`;

      for (const [key, , color] of config.series) {
        const pts = points.filter(p => p[key] != null).map(p => [x(+p.date), y(p[key])]);
        if (!pts.length) continue;
        const line = pts.map(([px, py]) => `${px.toFixed(1)},${py.toFixed(1)}`).join(" ");
        const base = y(0);
        // Only the first series is filled; two overlapping fills read as one grey slab.
        if (key === config.series[0][0]) out += `<polygon points="${pts[0][0].toFixed(1)},${base} ${line} ${pts[pts.length - 1][0].toFixed(1)},${base}" fill="url(#fill-${key})"/>`;
        out += `<polyline points="${line}" fill="none" style="stroke:var(${color})" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>`;
        if (pts.length <= 120) out += pts.map(([px, py]) => `<circle cx="${px.toFixed(1)}" cy="${py.toFixed(1)}" r="3" style="fill:var(${color})"/>`).join("");
      }
      out += `<line id="cursor" y1="${T}" y2="${H - B}" style="stroke:var(--muted);display:none" stroke-dasharray="3 3"/>`;
      svg.innerHTML = out;
      geometry = {points, x, config, W};
    }

    function showTip(clientX) {
      if (!geometry) return;
      const svg = $("chart"), box = svg.getBoundingClientRect();
      const px = (clientX - box.left) * geometry.W / box.width;
      let nearest = geometry.points[0];
      for (const p of geometry.points) if (Math.abs(geometry.x(+p.date) - px) < Math.abs(geometry.x(+nearest.date) - px)) nearest = p;
      const cx = geometry.x(+nearest.date);
      const cursor = $("cursor");
      cursor.setAttribute("x1", cx);
      cursor.setAttribute("x2", cx);
      cursor.style.display = "";
      const tip = $("tip");
      tip.innerHTML = `<div>${fmtTime(nearest.date)}</div>` + geometry.config.series
        .filter(([key]) => nearest[key] != null)
        .map(([key, label, color]) => `<div class="row"><i style="background:var(${color})"></i>${t(label)} <b>${num(nearest[key])}</b> ${t(geometry.config.unit)}</div>`).join("");
      tip.style.display = "block";
      // Beside the cursor, flipping to the left near the right edge.
      const card = svg.parentElement.getBoundingClientRect();
      const cursorX = box.left + cx * box.width / geometry.W - card.left;
      const right = cursorX + 12 + tip.offsetWidth <= card.width - 8;
      tip.style.left = `${right ? cursorX + 12 : Math.max(8, cursorX - 12 - tip.offsetWidth)}px`;
      tip.style.top = `${box.top - card.top + 8}px`;
    }

    function hideTip() {
      $("tip").style.display = "none";
      const cursor = $("cursor");
      if (cursor) cursor.style.display = "none";
    }

    $("chart").addEventListener("pointermove", e => showTip(e.clientX));
    $("chart").addEventListener("pointerleave", hideTip);

    renderSegments();
    load();
    refreshStatus();
    setInterval(() => { load(); refreshStatus(); }, 60000);
    addEventListener("resize", drawChart);
    </script>
    </body>
    </html>
    """#
}
