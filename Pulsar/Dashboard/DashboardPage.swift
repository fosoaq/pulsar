/// The LAN dashboard: one self-contained page, no external requests, so it works without internet.
enum DashboardPage {
    static let html = #"""
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Pulsar</title>
    <script>
      // Apply the saved theme before the first paint, so the page does not flash.
      try { const theme = localStorage.getItem("theme"); if (theme === "light" || theme === "dark") document.documentElement.dataset.theme = theme } catch (e) {}
    </script>
    <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='14' fill='%2318181b'/%3E%3Cpath d='M14 44a20 20 0 1 1 36 0' fill='none' stroke='white' stroke-width='6' stroke-linecap='round'/%3E%3Cpath d='M32 40 44 26' stroke='white' stroke-width='5' stroke-linecap='round'/%3E%3C/svg%3E">
    <style>
    :root{--bg:#fafafa;--text:#18181b;--muted:#71717a;--faint:#a1a1aa;--rule:#ececee;--accent:#2563eb;--second:#a1a1aa;--bad:#dc2626;color-scheme:light}
    /* Dark follows the system unless the viewer picked a theme in the footer. */
    @media (prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#0e0e10;--text:#ededef;--muted:#8b8b93;--faint:#5c5c64;--rule:#1d1d21;--accent:#6ea8fe;--second:#8b8b93;--bad:#f87171;color-scheme:dark}}
    :root[data-theme=dark]{--bg:#0e0e10;--text:#ededef;--muted:#8b8b93;--faint:#5c5c64;--rule:#1d1d21;--accent:#6ea8fe;--second:#8b8b93;--bad:#f87171;color-scheme:dark}
    *{box-sizing:border-box}
    body{margin:0;background:var(--bg);color:var(--text);font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",system-ui,sans-serif;-webkit-font-smoothing:antialiased}
    /* A column as tall as the window, so the footer sits at the bottom of short pages. */
    main{max-width:1080px;min-height:100vh;min-height:100dvh;margin:0 auto;padding:64px 32px 48px;display:flex;flex-direction:column}
    main>section{width:100%}
    @media (max-width:640px){main{padding:32px 20px 32px}}
    a{color:inherit}
    button,select{font:inherit;color:inherit}

    header{display:flex;flex-wrap:wrap;gap:24px 48px;align-items:center;justify-content:space-between}
    .brand h1{font-size:32px;font-weight:700;letter-spacing:-.03em;line-height:1.1;margin:0}
    .brand p{margin:6px 0 0;color:var(--muted);font-size:15px}
    .actions{display:flex;flex-wrap:wrap;gap:12px 20px;align-items:center}
    .run{background:var(--text);color:var(--bg);border:0;border-radius:10px;padding:11px 20px;font-size:15px;font-weight:500;cursor:pointer}
    .run:disabled{opacity:.4;cursor:default}
    select{background:none;border:0;padding:4px 0;color:var(--muted);font-size:14px;cursor:pointer;max-width:240px;text-align:right}
    select:focus-visible,button:focus-visible,a:focus-visible{outline:2px solid var(--accent);outline-offset:2px}

    nav{display:flex;flex-wrap:wrap;gap:16px 32px;align-items:baseline;justify-content:space-between;margin:56px 0 48px}
    .tabs,.options{display:flex;gap:28px}
    .options{gap:14px}
    .tabs a,.options button{background:none;border:0;padding:0;text-decoration:none;color:var(--faint);cursor:pointer}
    .tabs a{font-size:16px;font-weight:500}
    .options button{font-size:14px}
    .tabs a[aria-current=page],.options button[aria-pressed=true]{color:var(--text)}
    .tabs a:hover,.options button:hover{color:var(--text)}

    .metrics{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:32px;margin-bottom:20px}
    .metric .label{color:var(--muted);font-size:13px}
    .metric .value{font-size:44px;font-weight:600;letter-spacing:-.02em;font-variant-numeric:tabular-nums;line-height:1.15;margin-top:4px}
    .metric .value small{font-size:15px;font-weight:400;color:var(--muted);letter-spacing:0;margin-left:6px}
    .metric .note{color:var(--faint);font-size:13px;margin-top:4px;font-variant-numeric:tabular-nums}
    .last{color:var(--muted);font-size:14px;margin:0 0 72px}

    .section-head{display:flex;flex-wrap:wrap;gap:8px 24px;align-items:baseline;justify-content:space-between;margin:0 0 20px}
    h2{font-size:17px;font-weight:600;letter-spacing:-.01em;margin:0}
    .legend{display:flex;gap:18px;color:var(--muted);font-size:13px}
    .legend span::before{content:"";display:inline-block;width:12px;height:0;border-top:2px solid var(--c);vertical-align:middle;margin-right:7px}
    .legend span.dashed::before{border-top-style:dashed}
    .chart{position:relative;margin-bottom:80px}
    svg{display:block;width:100%;touch-action:pan-y;overflow:visible}
    svg text{fill:var(--faint);font-size:11px;font-variant-numeric:tabular-nums}
    .tip{position:absolute;pointer-events:none;background:var(--text);color:var(--bg);border-radius:8px;padding:8px 10px;font-size:12px;line-height:1.5;white-space:nowrap;display:none;z-index:2;font-variant-numeric:tabular-nums}
    .tip .when{opacity:.65}

    .table-wrap{overflow-x:auto;margin:0 -8px}
    table{width:100%;border-collapse:collapse;font-size:14px;font-variant-numeric:tabular-nums}
    th,td{text-align:left;padding:12px 8px;white-space:nowrap}
    th{color:var(--muted);font-weight:400;font-size:13px}
    tbody tr+tr td{border-top:1px solid var(--rule)}
    td.num,th.num{text-align:right;width:96px}
    td.wrap,td.err{white-space:normal;min-width:160px;max-width:280px}
    td.err{color:var(--bad)}
    td.dim{color:var(--muted)}
    td a{text-decoration:none}
    td a:hover{text-decoration:underline}
    .empty{color:var(--muted);padding:40px 0;text-align:center}
    .more{display:block;margin:20px auto 0;background:none;border:0;color:var(--muted);cursor:pointer;font-size:14px}
    .more:hover{color:var(--text)}

    .stats-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:64px 72px;margin-bottom:80px}
    .facts{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:32px;margin-bottom:80px}
    .bars rect{fill:var(--accent)}
    .bars rect.low{fill:var(--bad)}
    .muted{color:var(--muted)}
    a.muted{text-decoration:none}
    a.muted:hover{color:var(--text)}

    footer{margin-top:auto;padding-top:96px;color:var(--faint);font-size:13px;display:flex;flex-wrap:wrap;gap:12px 18px;align-items:baseline}
    footer .prefs{margin-left:auto;display:flex;flex-wrap:wrap;gap:12px 32px}
    footer .options{gap:12px}
    footer .options button{font-size:13px}
    footer a{text-decoration:none}
    footer a:hover{color:var(--text)}
    @media (max-width:640px){
      .actions{width:100%;flex-wrap:nowrap;justify-content:space-between}
      .actions select{flex:1;min-width:0;max-width:none;text-align:left;text-overflow:ellipsis}
      .run{white-space:nowrap}
      nav{margin:40px 0 32px}
      .metrics{grid-template-columns:1fr 1fr;gap:28px 16px}
      .metric .value{font-size:34px}
      .last{margin-bottom:48px}
      .chart{margin-bottom:56px}
      /* The recent tests keep to what fits; the Results tab scrolls sideways instead. */
      #recent .server{display:none}
      th,td{padding:10px 5px}
      td.num,th.num{width:auto}
      table{font-size:13px}
      .facts{grid-template-columns:1fr 1fr;margin-bottom:56px}
      .stats-grid{gap:56px;margin-bottom:56px}
      footer{padding-top:72px}
      footer .prefs{margin-left:0}
    }
    [hidden]{display:none!important}
    </style>
    </head>
    <body>
    <main>
    <header>
      <div class="brand">
        <h1>Pulsar</h1>
        <p><span id="subtitle" data-i18n>Internet speed monitor</span><span id="next"></span></p>
      </div>
      <div class="actions">
        <select id="server" hidden aria-label="Server"></select>
        <button class="run" id="run" data-i18n>Run test</button>
      </div>
    </header>

    <nav>
      <div class="tabs">
        <a href="#overview" data-tab="overview" data-i18n>Overview</a>
        <a href="#results" data-tab="results" data-i18n>Results</a>
        <a href="#statistics" data-tab="statistics" data-i18n>Statistics</a>
      </div>
      <div class="options" id="ranges"></div>
    </nav>

    <section id="overview">
      <div class="metrics" id="metrics"></div>
      <p class="last" id="last"></p>
      <div class="section-head">
        <div class="legend" id="legend"></div>
        <div class="options" id="kinds"></div>
      </div>
      <div class="chart"><svg id="chart" role="img" aria-label="Results over time"></svg><div class="tip" id="tip"></div></div>
      <div class="section-head"><h2 data-i18n>Recent tests</h2><a class="muted" href="#results" data-i18n>All results</a></div>
      <div class="table-wrap"><table id="recent"></table></div>
    </section>

    <section id="results" hidden>
      <div class="section-head">
        <div class="options" id="filters"></div>
        <a class="muted" id="csv" href="/api/results.csv?days=7" data-i18n>Download CSV</a>
      </div>
      <div class="table-wrap"><table id="all"></table></div>
      <button class="more" id="more" hidden data-i18n>Show more</button>
    </section>

    <section id="statistics" hidden>
      <div class="facts" id="facts"></div>
      <div class="stats-grid">
        <div><div class="section-head"><h2 data-i18n>Summary</h2><span class="muted" id="summary-engine"></span></div><div class="table-wrap"><table id="summary"></table></div></div>
        <div><div class="section-head"><h2 data-i18n>Download by hour of day</h2></div><svg id="hours" class="bars" role="img" aria-label="Average download by hour of day"></svg></div>
      </div>
      <div class="section-head"><h2 data-i18n>By server</h2></div>
      <div class="table-wrap"><table id="servers"></table></div>
    </section>

    <footer><span id="version">Pulsar</span><a href="/api/results">JSON</a><a href="/metrics">Prometheus</a><a href="https://github.com/fosoaq/pulsar">GitHub</a><div class="prefs"><div class="options" id="theme" aria-label="Theme"></div><div class="options" id="lang" aria-label="Language"></div></div></footer>
    </main>
    <script>
    // Russian when the browser prefers it; English otherwise.
    const RU = {
      "Internet speed monitor": "Мониторинг скорости интернета", "Internet speed on": "Скорость интернета на",
      "Run test": "Запустить тест", "Testing…": "Идёт тест…", "Overview": "Обзор", "Results": "Результаты", "Statistics": "Статистика",
      "Download": "Загрузка", "Upload": "Отдача", "Ping": "Пинг", "Jitter": "Джиттер", "Loaded ping": "Пинг под нагрузкой", "under load": "под нагрузкой",
      "Ping during download": "Пинг при загрузке", "Ping during upload": "Пинг при отдаче", "Loss": "Потери",
      "Server": "Сервер", "Time": "Время", "Engine": "Движок", "Speed": "Скорость",
      "avg": "в среднем", "Mbps": "Мбит/с", "ms": "мс", "No data": "Нет данных",
      "No tests in this range yet.": "За этот период тестов нет.", "next test at": "следующий тест в",
      "Tests paused": "Тесты на паузе", "Could not load results": "Не удалось загрузить результаты",
      "Accept the Speedtest license in Pulsar's settings first": "Сначала примите лицензию Speedtest в настройках Pulsar",
      "24h": "24ч", "7d": "7д", "30d": "30д", "90d": "90д", "Show more": "Показать ещё",
      "Last test": "Последний тест", "minutes ago": "мин назад", "just now": "только что",
      "Recent tests": "Последние тесты", "All results": "Все результаты", "Download CSV": "Скачать CSV",
      "All": "Все", "Failures": "Ошибки", "Nearest server": "Ближайший сервер",
      "Summary": "Сводка", "Average": "Среднее", "Median": "Медиана", "Lowest": "Минимум", "Highest": "Максимум",
      "Download by hour of day": "Загрузка по часам суток", "By server": "По серверам", "Tests": "Тестов",
      "Success rate": "Успешных", "failed": "с ошибкой", "Below threshold": "Ниже порога", "Slowest hour": "Самый медленный час",
      "of": "из", "Auto": "Авто", "Light": "Светлая", "Dark": "Тёмная",
    };
    const prefs = {
      get(key, fallback) { try { return localStorage.getItem(key) ?? fallback } catch (e) { return fallback } },
      set(key, value) { try { localStorage.setItem(key, value) } catch (e) {} },
    };
    // Russian when picked in the footer, or on Auto when the browser prefers it.
    const language = ["en", "ru"].includes(prefs.get("lang", "auto")) ? prefs.get("lang", "auto") : "auto";
    const prefersRussian = /^ru\b/i.test((navigator.languages || [])[0] || navigator.language || "");
    const L10N = language === "ru" || (language === "auto" && prefersRussian) ? RU : {};
    const t = s => L10N[s] || s;
    // Dates follow the page language, not only the browser's.
    const LOCALE = L10N === RU ? "ru" : [];
    if (L10N === RU) document.documentElement.lang = "ru";
    document.querySelectorAll("[data-i18n]").forEach(el => { el.textContent = t(el.textContent) });

    const RANGES = [["24h", 1], ["7d", 7], ["30d", 30], ["90d", 90]];
    const KINDS = {
      speed: {label: "Speed", unit: "Mbps", series: [["downloadMbps", "Download", "--accent"], ["uploadMbps", "Upload", "--second"]]},
      ping: {label: "Ping", unit: "ms", series: [["latencyMs", "Ping", "--accent"], ["downloadLatencyMs", "Ping during download", "--second"], ["uploadLatencyMs", "Ping during upload", "--second", true]]},
    };
    const ENGINES = {ookla: "Ookla", networkQuality: "networkQuality"};
    const TABS = ["overview", "results", "statistics"];
    const PAGE = 50;

    let days = Number(prefs.get("days", 7)) || 7;
    let kind = KINDS[prefs.get("kind", "speed")] ? prefs.get("kind", "speed") : "speed";
    let failuresOnly = false;
    let shown = PAGE;
    let data = [];
    let status = null;

    const $ = id => document.getElementById(id);
    const esc = s => String(s).replace(/[&<>"']/g, c => ({"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"}[c]));
    const num = v => v == null || isNaN(v) ? "—" : v >= 100 ? v.toFixed(0) : String(+v.toFixed(v >= 10 ? 1 : 2));
    const fmtTime = d => d.toLocaleString(LOCALE, {month: "short", day: "numeric", hour: "2-digit", minute: "2-digit"});
    const fmtClock = d => d.toLocaleTimeString(LOCALE, {hour: "2-digit", minute: "2-digit"});
    const hourLabel = hour => new Date(2000, 0, 1, hour).toLocaleTimeString(LOCALE, {hour: "numeric"});
    const values = (rows, key) => rows.map(r => r[key]).filter(v => v != null);
    const mean = xs => xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : null;
    const median = xs => {
      if (!xs.length) return null;
      const s = [...xs].sort((a, b) => a - b), m = s.length >> 1;
      return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
    };
    const ago = d => {
      const minutes = Math.round((Date.now() - d) / 60000);
      if (minutes < 1) return t("just now");
      if (minutes < 60) return `${minutes} ${t("minutes ago")}`;
      return fmtTime(d);
    };
    const empty = `<tbody><tr><td class="empty">${t("No tests in this range yet.")}</td></tr></tbody>`;

    // Tabs live in the URL hash, so a tab can be bookmarked.
    const currentTab = () => TABS.includes(location.hash.slice(1)) ? location.hash.slice(1) : "overview";
    function showTab() {
      const tab = currentTab();
      document.querySelectorAll("[data-tab]").forEach(a => a.dataset.tab === tab ? a.setAttribute("aria-current", "page") : a.removeAttribute("aria-current"));
      for (const id of TABS) $(id).hidden = id !== tab;
      render();
    }
    addEventListener("hashchange", () => { showTab(); scrollTo(0, 0) });

    function options(container, items, active, attribute) {
      $(container).innerHTML = items.map(([label, value]) => `<button aria-pressed="${value === active}" data-${attribute}="${value}">${t(label)}</button>`).join("");
    }
    function renderOptions() {
      options("ranges", RANGES, days, "days");
      options("kinds", Object.entries(KINDS).map(([key, k]) => [k.label, key]), kind, "kind");
      options("filters", [["All", "all"], ["Failures", "failures"]], failuresOnly ? "failures" : "all", "filter");
      options("theme", [["Auto", "auto"], ["Light", "light"], ["Dark", "dark"]], document.documentElement.dataset.theme || "auto", "theme");
      // Language names stay in their own language, so each is recognizable in the other.
      $("lang").innerHTML = [["Auto", "auto"], ["English", "en"], ["Русский", "ru"]]
        .map(([label, value]) => `<button aria-pressed="${value === language}" data-lang="${value}">${value === "auto" ? t(label) : label}</button>`).join("");
      $("legend").innerHTML = KINDS[kind].series.map(([, label, color, dashed]) => `<span style="--c:var(${color})"${dashed ? ' class="dashed"' : ""}>${t(label)}</span>`).join("");
    }
    function onOption(container, handle) {
      $(container).addEventListener("click", e => { const b = e.target.closest("button"); if (b) handle(b.dataset) });
    }
    onOption("ranges", d => { days = Number(d.days); prefs.set("days", days); shown = PAGE; renderOptions(); load() });
    onOption("kinds", d => { kind = d.kind; prefs.set("kind", kind); renderOptions(); drawChart() });
    onOption("filters", d => { failuresOnly = d.filter === "failures"; shown = PAGE; renderOptions(); renderResults() });
    $("more").addEventListener("click", () => { shown += PAGE; renderResults() });
    onOption("theme", d => {
      if (d.theme === "auto") delete document.documentElement.dataset.theme; else document.documentElement.dataset.theme = d.theme;
      prefs.set("theme", d.theme);
      renderOptions();
    });
    onOption("lang", d => { prefs.set("lang", d.lang); location.reload() });

    // Status, server list and running a test
    let wasRunning = false;
    async function refreshStatus() {
      try {
        status = await (await fetch("/api/status")).json();
        const button = $("run");
        button.disabled = status.running || status.paused;
        button.textContent = t(status.running ? "Testing…" : "Run test");
        button.title = status.paused ? t("Accept the Speedtest license in Pulsar's settings first") : "";
        $("next").textContent = " · " + (status.running ? t("Testing…") : status.paused ? t("Tests paused") : `${t("next test at")} ${fmtClock(new Date(status.nextRun))}`);
        if (status.hostName) $("subtitle").textContent = `${t("Internet speed on")} ${status.hostName}`;
        if (status.version) $("version").textContent = `Pulsar ${status.version}`;
        if (status.engine === "ookla" && $("server").hidden) loadServers();
        if (status.engine !== "ookla") $("server").hidden = true;
        if (wasRunning && !status.running) load();
        wasRunning = status.running;
        if (status.running) setTimeout(refreshStatus, 3000);
      } catch (e) {}
    }

    async function loadServers() {
      try {
        const servers = await (await fetch("/api/servers")).json();
        if (!servers.length) return;
        const select = $("server");
        select.innerHTML = `<option value="">${t("Nearest server")}</option>` +
          servers.map(s => `<option value="${s.id}">${esc([s.name, s.location].filter(Boolean).join(", "))}</option>`).join("");
        select.value = status?.serverID ?? "";
        select.hidden = false;
      } catch (e) {}
    }

    $("run").addEventListener("click", async () => {
      $("run").disabled = true;
      const server = $("server").hidden ? "" : $("server").value;
      await fetch(`/api/run${server ? `?server=${encodeURIComponent(server)}` : ""}`, {method: "POST", headers: {"X-Pulsar-Run": "1"}});
      refreshStatus();
    });

    async function load() {
      try {
        const response = await fetch(`/api/results?days=${days}`);
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        data = (await response.json()).map(r => ({...r, date: new Date(r.date)}));
        $("csv").href = `/api/results.csv?days=${days}`;
        render();
      } catch (e) {
        $("last").textContent = `${t("Could not load results")}: ${e.message}`;
      }
    }

    function render() {
      ({overview: renderOverview, results: renderResults, statistics: renderStatistics})[currentTab()]();
    }

    // Overview
    function renderOverview() {
      const ok = data.filter(r => !r.error);
      const last = ok[0];
      // Averages use the latest engine only: the two engines measure against different servers.
      const same = ok.filter(r => r.engine === last?.engine);
      const metric = (label, key, unit, note) =>
        `<div class="metric"><div class="label">${t(label)}</div><div class="value">${num(last?.[key])}<small>${t(unit)}</small></div>` +
        `<div class="note">${note ?? (same.length > 1 ? `${t("avg")} ${num(mean(values(same, key)))}` : "&nbsp;")}</div></div>`;
      const loaded = last?.downloadLatencyMs != null || last?.uploadLatencyMs != null
        ? `${num(last.downloadLatencyMs)} / ${num(last.uploadLatencyMs)} ${t("under load")}`
        : undefined;
      $("metrics").innerHTML = metric("Download", "downloadMbps", "Mbps") + metric("Upload", "uploadMbps", "Mbps") +
        metric("Ping", "latencyMs", "ms", loaded) + (last?.jitterMs != null ? metric("Jitter", "jitterMs", "ms") : "");
      $("last").textContent = last
        ? `${t("Last test")} ${ago(last.date)} · ${[ENGINES[last.engine] || last.engine, last.server].filter(Boolean).join(" · ")}`
        : t("No tests in this range yet.");
      drawChart();
      $("recent").innerHTML = table(data.slice(0, 5), false);
    }

    function table(rows, full) {
      if (!rows.length) return empty;
      const head = `<thead><tr><th>${t("Time")}</th><th class="num">${t("Download")}</th><th class="num">${t("Upload")}</th><th class="num">${t("Ping")}</th>` +
        (full ? `<th class="num">${t("Jitter")}</th><th class="num">${t("Loaded ping")}</th><th class="num">${t("Loss")}</th>` : "") + `<th class="server">${t("Server")}</th>${full ? `<th>${t("Engine")}</th>` : ""}</tr></thead>`;
      const body = rows.map(r => {
        const time = r.resultURL ? `<a href="${esc(r.resultURL)}" target="_blank" rel="noopener">${fmtTime(r.date)}</a>` : fmtTime(r.date);
        if (r.error) return `<tr><td>${time}</td><td class="err" colspan="${full ? 8 : 4}">${esc(r.error)}</td></tr>`;
        return `<tr><td>${time}</td><td class="num">${num(r.downloadMbps)}</td><td class="num">${num(r.uploadMbps)}</td><td class="num">${num(r.latencyMs)}</td>` +
          (full ? `<td class="num">${num(r.jitterMs)}</td><td class="num">${r.downloadLatencyMs != null || r.uploadLatencyMs != null ? `${num(r.downloadLatencyMs)} / ${num(r.uploadLatencyMs)}` : "—"}</td><td class="num">${r.packetLossPercent != null ? num(r.packetLossPercent) + "%" : "—"}</td>` : "") +
          `<td class="wrap dim server">${r.server ? esc(r.server) : "—"}</td>${full ? `<td class="dim">${esc(ENGINES[r.engine] || r.engine)}</td>` : ""}</tr>`;
      }).join("");
      return head + `<tbody>${body}</tbody>`;
    }

    // Results
    function renderResults() {
      const rows = failuresOnly ? data.filter(r => r.error) : data;
      $("all").innerHTML = table(rows.slice(0, shown), true);
      $("more").hidden = rows.length <= shown;
    }

    // Statistics
    function renderStatistics() {
      const ok = data.filter(r => !r.error);
      const failed = data.length - ok.length;
      const thresholds = status && (status.minDownloadMbps > 0 || status.minUploadMbps > 0);
      const below = thresholds
        ? ok.filter(r => (status.minDownloadMbps > 0 && r.downloadMbps < status.minDownloadMbps) || (status.minUploadMbps > 0 && r.uploadMbps < status.minUploadMbps)).length
        : null;
      const hours = Array.from({length: 24}, (_, hour) => ({hour, avg: mean(values(ok.filter(r => r.date.getHours() === hour), "downloadMbps"))}));
      const measured = hours.filter(h => h.avg != null);
      const slowest = measured.length > 1 ? [...measured].sort((a, b) => a.avg - b.avg)[0] : null;
      // Only a real dip is worth marking: 10% below the average of the other hours.
      const others = slowest && mean(measured.filter(h => h !== slowest).map(h => h.avg));
      const dip = slowest && slowest.avg < others * 0.9 ? slowest : null;
      const fact = (label, value, note = "") => `<div class="metric"><div class="label">${t(label)}</div><div class="value">${value}</div><div class="note">${note || "&nbsp;"}</div></div>`;
      $("facts").innerHTML =
        fact("Tests", data.length) +
        fact("Success rate", data.length ? `${Math.round(ok.length / data.length * 100)}%` : "—", failed ? `${failed} ${t("failed")}` : "") +
        (below != null ? fact("Below threshold", below, `${t("of")} ${ok.length}`) : "") +
        fact("Slowest hour", slowest ? hourLabel(slowest.hour) : "—", slowest ? `${num(slowest.avg)} ${t("Mbps")}` : "");

      // The two engines measure against different servers, so the summary covers the latest one.
      const engine = ok[0]?.engine;
      const same = ok.filter(r => r.engine === engine);
      const engines = new Set(ok.map(r => r.engine));
      $("summary-engine").textContent = engines.size > 1 ? ENGINES[engine] || engine : "";
      const row = (label, key, unit) => {
        const xs = values(same, key);
        return `<tr><td>${t(label)}</td><td class="num">${num(mean(xs))}</td><td class="num">${num(median(xs))}</td>` +
          `<td class="num">${num(xs.length ? Math.min(...xs) : null)}</td><td class="num">${num(xs.length ? Math.max(...xs) : null)}</td><td class="dim">${t(unit)}</td></tr>`;
      };
      $("summary").innerHTML = ok.length
        ? `<thead><tr><th></th><th class="num">${t("Average")}</th><th class="num">${t("Median")}</th><th class="num">${t("Lowest")}</th><th class="num">${t("Highest")}</th><th></th></tr></thead><tbody>` +
          row("Download", "downloadMbps", "Mbps") + row("Upload", "uploadMbps", "Mbps") + row("Ping", "latencyMs", "ms") + row("Jitter", "jitterMs", "ms") +
          (values(same, "downloadLatencyMs").length ? row("Ping during download", "downloadLatencyMs", "ms") + row("Ping during upload", "uploadLatencyMs", "ms") : "") + "</tbody>"
        : empty;

      drawHours(hours, dip);

      const groups = new Map();
      for (const r of ok) {
        const key = r.server || ENGINES[r.engine] || r.engine;
        if (!groups.has(key)) groups.set(key, []);
        groups.get(key).push(r);
      }
      const servers = [...groups.entries()].sort((a, b) => b[1].length - a[1].length);
      $("servers").innerHTML = servers.length
        ? `<thead><tr><th>${t("Server")}</th><th class="num">${t("Tests")}</th><th class="num">${t("Download")}</th><th class="num">${t("Upload")}</th><th class="num">${t("Ping")}</th></tr></thead><tbody>` +
          servers.map(([name, rows]) => `<tr><td class="wrap">${esc(name)}</td><td class="num dim">${rows.length}</td><td class="num">${num(mean(values(rows, "downloadMbps")))}</td>` +
            `<td class="num">${num(mean(values(rows, "uploadMbps")))}</td><td class="num">${num(mean(values(rows, "latencyMs")))}</td></tr>`).join("") + "</tbody>"
        : empty;
    }

    function drawHours(hours, slowest) {
      const svg = $("hours");
      const W = svg.clientWidth || 480, H = 180, B = 20, T = 8;
      svg.setAttribute("viewBox", `0 0 ${W} ${H}`);
      svg.style.height = `${H}px`;
      const max = Math.max(...hours.map(h => h.avg || 0));
      if (!max) { svg.innerHTML = `<text x="${W / 2}" y="${H / 2}" text-anchor="middle">${t("No data")}</text>`; return }
      const slot = W / 24, bar = Math.max(2, slot * 0.6);
      svg.innerHTML = hours.map(h => {
        const x = h.hour * slot + (slot - bar) / 2;
        const height = h.avg ? Math.max(2, h.avg / max * (H - B - T)) : 0;
        const label = h.hour % 6 === 0 ? `<text x="${(x + bar / 2).toFixed(1)}" y="${H - 4}" text-anchor="middle">${hourLabel(h.hour)}</text>` : "";
        const rect = height
          ? `<rect x="${x.toFixed(1)}" y="${(H - B - height).toFixed(1)}" width="${bar.toFixed(1)}" height="${height.toFixed(1)}" rx="2"${h === slowest ? ' class="low"' : ""}><title>${hourLabel(h.hour)} · ${num(h.avg)} ${t("Mbps")}</title></rect>`
          : `<rect x="${x.toFixed(1)}" y="${H - B - 1}" width="${bar.toFixed(1)}" height="1" style="fill:var(--rule)"/>`;
        return rect + label;
      }).join("");
    }

    // Chart. The time axis spans the data rather than the whole range, so a few tests
    // from the last hour do not collapse into one spot at the right edge of a week.
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
      const config = KINDS[kind];
      const points = data.filter(r => !r.error).slice().reverse();
      const W = svg.clientWidth || 800, H = 260, L = 40, R = 4, T = 8, B = 26;
      svg.setAttribute("viewBox", `0 0 ${W} ${H}`);
      svg.style.height = `${H}px`;
      geometry = null;
      $("tip").style.display = "none";
      if (!points.length) {
        svg.innerHTML = `<text x="${W / 2}" y="${H / 2}" text-anchor="middle">${t("No data")}</text>`;
        return;
      }

      const first = +points[0].date, last = +points[points.length - 1].date;
      const span = Math.max(last - first, 30 * 60000);
      const t0 = Math.max(Date.now() - days * 864e5, first - span * 0.03);
      const t1 = last + span * 0.03;
      const all = points.flatMap(p => config.series.map(([key]) => p[key])).filter(v => v != null);
      const max = niceMax(Math.max(...all, 0) * 1.05);
      const x = time => L + (time - t0) / (t1 - t0) * (W - L - R);
      const y = v => T + (1 - v / max) * (H - T - B);

      let out = `<line x1="${L}" x2="${W - R}" y1="${y(0)}" y2="${y(0)}" style="stroke:var(--rule)"/>`;
      for (let i = 0; i <= 4; i++) out += `<text x="0" y="${y(max * i / 4) + 4}">${num(max * i / 4)}</text>`;
      const {ticks, daily} = timeTicks(t0, t1, Math.max(3, Math.floor((W - L - R) / 100)));
      for (const tick of ticks) {
        const d = new Date(tick);
        const midnight = d.getHours() === 0 && d.getMinutes() === 0;
        out += `<text x="${x(tick)}" y="${H - 6}" text-anchor="middle">${daily || midnight ? d.toLocaleDateString(LOCALE, {month: "short", day: "numeric"}) : fmtClock(d)}</text>`;
      }
      // The second series first, so the main one sits on top.
      for (const [key, , color, dashed] of [...config.series].reverse()) {
        const pts = points.filter(p => p[key] != null).map(p => [x(+p.date), y(p[key])]);
        if (!pts.length) continue;
        out += pts.length === 1
          ? `<circle cx="${pts[0][0]}" cy="${pts[0][1]}" r="3" style="fill:var(${color})"/>`
          : `<polyline points="${pts.map(([px, py]) => `${px.toFixed(1)},${py.toFixed(1)}`).join(" ")}" fill="none" style="stroke:var(${color})"${dashed ? ' stroke-dasharray="4 4"' : ""} stroke-width="1.75" stroke-linejoin="round" stroke-linecap="round"/>`;
      }
      out += `<line id="cursor" y1="${T}" y2="${H - B}" style="stroke:var(--faint);display:none"/>`;
      out += config.series.map(([key, , color]) => `<circle id="dot-${key}" r="3.5" style="fill:var(${color});stroke:var(--bg);stroke-width:2;display:none"/>`).join("");
      svg.innerHTML = out;
      geometry = {points, x, y, config, W};
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
      for (const [key] of geometry.config.series) {
        const dot = $(`dot-${key}`);
        if (nearest[key] == null) { dot.style.display = "none"; continue }
        dot.setAttribute("cx", cx);
        dot.setAttribute("cy", geometry.y(nearest[key]));
        dot.style.display = "";
      }
      const tip = $("tip");
      tip.innerHTML = `<div class="when">${fmtTime(nearest.date)}</div>` + geometry.config.series
        .filter(([key]) => nearest[key] != null)
        .map(([key, label]) => `<div>${t(label)} ${num(nearest[key])} ${t(geometry.config.unit)}</div>`).join("");
      tip.style.display = "block";
      // Beside the cursor, flipping to the left near the right edge.
      const wrap = svg.parentElement.getBoundingClientRect();
      const cursorX = box.left + cx * box.width / geometry.W - wrap.left;
      const right = cursorX + 14 + tip.offsetWidth <= wrap.width;
      tip.style.left = `${right ? cursorX + 14 : Math.max(0, cursorX - 14 - tip.offsetWidth)}px`;
      tip.style.top = "0px";
    }

    function hideTip() {
      $("tip").style.display = "none";
      for (const el of document.querySelectorAll("#cursor, [id^=dot-]")) el.style.display = "none";
    }

    $("chart").addEventListener("pointermove", e => showTip(e.clientX));
    $("chart").addEventListener("pointerleave", hideTip);

    renderOptions();
    showTab();
    load();
    refreshStatus();
    setInterval(() => { load(); refreshStatus(); }, 60000);
    addEventListener("resize", render);
    </script>
    </body>
    </html>
    """#
}
