/// The LAN dashboard: one self-contained page, no external requests, so it works without internet.
enum DashboardPage {
    static let html = #"""
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Pulsar</title>
    <style>
    :root{--bg:#f5f6f8;--card:#fff;--text:#16181d;--muted:#6b7280;--line:#e4e7ec;--down:#2563eb;--up:#ea580c;--bad:#dc2626;color-scheme:light}
    @media (prefers-color-scheme:dark){:root{--bg:#0f1115;--card:#171a21;--text:#e8eaf0;--muted:#9aa3b2;--line:#2a2f3a;--down:#60a5fa;--up:#fb923c;--bad:#f87171;color-scheme:dark}}
    *{box-sizing:border-box}
    body{margin:0;background:var(--bg);color:var(--text);font:15px/1.45 -apple-system,BlinkMacSystemFont,"Segoe UI",system-ui,sans-serif}
    main{max-width:1040px;margin:0 auto;padding:24px 16px 48px}
    header{display:flex;flex-wrap:wrap;gap:12px;align-items:center;justify-content:space-between;margin-bottom:20px}
    h1{font-size:22px;margin:0}
    .sub{color:var(--muted);font-size:13px}
    .ranges{display:flex;gap:4px;background:var(--card);border:1px solid var(--line);border-radius:10px;padding:3px}
    .ranges button{border:0;background:none;color:var(--text);padding:6px 12px;border-radius:7px;font:inherit;font-size:13px;cursor:pointer}
    .ranges button[aria-pressed=true]{background:var(--down);color:#fff}
    .tiles{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:12px;margin-bottom:16px}
    .card{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:16px}
    .tile .label{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.04em}
    .tile .value{font-size:28px;font-weight:650;font-variant-numeric:tabular-nums;margin-top:4px}
    .tile .value small{font-size:14px;color:var(--muted);font-weight:500;margin-left:4px}
    .tile .hint{color:var(--muted);font-size:12px;margin-top:2px}
    .chart{margin-bottom:16px}
    .legend{display:flex;gap:16px;font-size:13px;color:var(--muted);margin-bottom:8px}
    .legend i{display:inline-block;width:10px;height:10px;border-radius:3px;margin-right:6px;vertical-align:-1px}
    svg{display:block;width:100%;height:260px}
    svg text{fill:var(--muted);font-size:11px}
    .table-wrap{overflow-x:auto}
    table{width:100%;border-collapse:collapse;font-size:14px;font-variant-numeric:tabular-nums}
    th,td{text-align:left;padding:8px 10px;border-bottom:1px solid var(--line);white-space:nowrap}
    th{color:var(--muted);font-weight:500;font-size:12px;text-transform:uppercase}
    td.err{color:var(--bad);white-space:normal;min-width:220px}
    .empty{color:var(--muted);padding:32px;text-align:center}
    </style>
    </head>
    <body>
    <main>
    <header>
      <div><h1>Pulsar</h1><div class="sub" id="updated">Loading…</div></div>
      <div class="ranges" id="ranges"></div>
    </header>
    <section class="tiles" id="tiles"></section>
    <section class="card chart">
      <div class="legend"><span><i style="background:var(--down)"></i>Download</span><span><i style="background:var(--up)"></i>Upload</span></div>
      <svg id="chart" role="img" aria-label="Download and upload speed over time"></svg>
    </section>
    <section class="card table-wrap">
      <table>
        <thead><tr><th>Time</th><th>Download</th><th>Upload</th><th>Latency</th><th>Jitter</th><th>Responsiveness</th><th>Server</th><th>Status</th></tr></thead>
        <tbody id="rows"></tbody>
      </table>
    </section>
    </main>
    <script>
    const RANGES = [["24h", 1], ["7d", 7], ["30d", 30], ["90d", 90]];
    let days = 7;
    try { days = Number(localStorage.getItem("days")) || 7 } catch (e) {}
    let data = [];

    const $ = id => document.getElementById(id);
    const esc = s => String(s).replace(/[&<>"']/g, c => ({"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"}[c]));
    const mbps = v => v == null ? "—" : (v >= 100 ? v.toFixed(0) : v.toFixed(1));
    const ms = v => v == null ? "—" : Math.round(v) + " ms";
    const fmtTime = d => d.toLocaleString([], {month: "short", day: "numeric", hour: "2-digit", minute: "2-digit"});
    const avg = xs => { xs = xs.filter(v => v != null); return xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : null };

    function renderRanges() {
      $("ranges").innerHTML = RANGES.map(([label, d]) => `<button aria-pressed="${d === days}" data-days="${d}">${label}</button>`).join("");
    }

    $("ranges").addEventListener("click", e => {
      const button = e.target.closest("button");
      if (!button) return;
      days = Number(button.dataset.days);
      try { localStorage.setItem("days", days) } catch (e) {}
      renderRanges();
      load();
    });

    async function load() {
      try {
        const response = await fetch(`/api/results?days=${days}`);
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        data = (await response.json()).map(r => ({...r, date: new Date(r.date)}));
        render();
        $("updated").textContent = `Updated ${new Date().toLocaleTimeString([], {hour: "2-digit", minute: "2-digit"})}`;
      } catch (e) {
        $("updated").textContent = `Could not load results: ${e.message}`;
      }
    }

    function render() {
      const ok = data.filter(r => !r.error);
      const last = ok[0];
      const failed = data.length - ok.length;
      const tile = (label, value, unit, hint) =>
        `<div class="card tile"><div class="label">${label}</div><div class="value">${value}${unit ? `<small>${unit}</small>` : ""}</div><div class="hint">${hint}</div></div>`;
      $("tiles").innerHTML = [
        tile("Download", mbps(last?.downloadMbps), "Mbps", `avg ${mbps(avg(ok.map(r => r.downloadMbps)))}`),
        tile("Upload", mbps(last?.uploadMbps), "Mbps", `avg ${mbps(avg(ok.map(r => r.uploadMbps)))}`),
        tile("Latency", last?.latencyMs != null ? Math.round(last.latencyMs) : "—", "ms", `avg ${ms(avg(ok.map(r => r.latencyMs)))}`),
        tile("Last test", last ? fmtTime(last.date) : "—", "", last ? esc(last.engine) : ""),
        tile("Tests", data.length, "", failed ? `${failed} failed` : "all succeeded"),
      ].join("");

      drawChart();

      $("rows").innerHTML = data.length
        ? data.slice(0, 200).map(r => `<tr>
            <td>${fmtTime(r.date)}</td>
            <td>${mbps(r.downloadMbps)}</td>
            <td>${mbps(r.uploadMbps)}</td>
            <td>${ms(r.latencyMs)}</td>
            <td>${ms(r.jitterMs)}</td>
            <td>${r.responsivenessRPM != null ? Math.round(r.responsivenessRPM) + " RPM" : "—"}</td>
            <td>${r.server ? esc(r.server) : "—"}</td>
            ${r.error ? `<td class="err">${esc(r.error)}</td>` : "<td>OK</td>"}
          </tr>`).join("")
        : `<tr><td colspan="8" class="empty">No tests in this range yet.</td></tr>`;
    }

    function drawChart() {
      const points = data.filter(r => !r.error).reverse();
      const svg = $("chart");
      const W = svg.clientWidth || 800, H = 260, L = 44, R = 12, T = 10, B = 26;
      svg.setAttribute("viewBox", `0 0 ${W} ${H}`);
      if (!points.length) {
        svg.innerHTML = `<text x="${W / 2}" y="${H / 2}" text-anchor="middle">No data</text>`;
        return;
      }
      const max = Math.max(1, ...points.flatMap(p => [p.downloadMbps || 0, p.uploadMbps || 0])) * 1.1;
      const t1 = Date.now(), t0 = t1 - days * 864e5;
      const x = t => L + (t - t0) / (t1 - t0) * (W - L - R);
      const y = v => T + (1 - v / max) * (H - T - B);

      let out = "";
      for (let i = 0; i <= 4; i++) {
        const v = max * i / 4, yy = y(v);
        out += `<line x1="${L}" x2="${W - R}" y1="${yy}" y2="${yy}" style="stroke:var(--line)"/>`;
        out += `<text x="${L - 6}" y="${yy + 4}" text-anchor="end">${Math.round(v)}</text>`;
      }
      for (let i = 0; i <= 4; i++) {
        const t = t0 + (t1 - t0) * i / 4, d = new Date(t);
        const label = days <= 1 ? d.toLocaleTimeString([], {hour: "2-digit", minute: "2-digit"}) : d.toLocaleDateString([], {month: "short", day: "numeric"});
        out += `<text x="${x(t)}" y="${H - 6}" text-anchor="${i === 0 ? "start" : i === 4 ? "end" : "middle"}">${label}</text>`;
      }
      const series = (key, color) => {
        const pts = points.filter(p => p[key] != null);
        const line = `<polyline points="${pts.map(p => `${x(+p.date).toFixed(1)},${y(p[key]).toFixed(1)}`).join(" ")}" fill="none" style="stroke:${color}" stroke-width="2" stroke-linejoin="round"/>`;
        const dots = pts.length <= 150
          ? pts.map(p => `<circle cx="${x(+p.date)}" cy="${y(p[key])}" r="3" style="fill:${color}"><title>${fmtTime(p.date)}: ${mbps(p[key])} Mbps</title></circle>`).join("")
          : "";
        return line + dots;
      };
      svg.innerHTML = out + series("downloadMbps", "var(--down)") + series("uploadMbps", "var(--up)");
    }

    renderRanges();
    load();
    setInterval(load, 60000);
    addEventListener("resize", drawChart);
    </script>
    </body>
    </html>
    """#
}
