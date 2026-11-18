// node run.js check   -> consistency checks + entropy check of the CDT sampler (2D CDT counts grow as 2^N: lambda_c = ln 2)
// node run.js dims    -> Hausdorff dimension of DT and CDT: ball growth and size scaling
const { DT, CDT, shells, meanDistance, rng } = require("./tri.js");
const mode = process.argv[2] || "check";
let fail = 0; const ok = (n, c, d) => { console.log(`${c ? "PASS" : "FAIL"}  ${n}  ${d}`); if (!c) fail++; };
const mean = v => v.reduce((a, b) => a + b, 0) / v.length;
const fitSlope = (xs, ys) => { const n = xs.length, mx = mean(xs), my = mean(ys); let a = 0, b = 0; for (let i = 0; i < n; i++) { a += (xs[i] - mx) * (ys[i] - my); b += (xs[i] - mx) ** 2; } return a / b; };
if (mode === "check") {
  { const d = new DT(4000, 3); for (let k = 0; k < 100; k++) d.sweep(); const c = d.check();
    ok("DT stays a valid sphere triangulation after 100 sweeps", c.euler === 2 && c.twice && c.adjOK && c.nbOK && c.minDeg >= 3, JSON.stringify(c)); }
  { const c = new CDT(20, 20, 5, 800, 0.002); for (let k = 0; k < 300; k++) c.sweep(); const k = c.check();
    ok("CDT stays a valid torus triangulation after 300 sweeps", k.counts && k.euler === 0 && k.sym && k.minL >= 3, JSON.stringify(k) + ` N ${c.N}`); }
  // Entropy check. With weight exp(-eps (N - N0)^2) and configuration counts ~ 2^N (exact 2D CDT result g_c = 1/2,
  // Ambjorn & Loll hep-th/9805108), the volume should settle at N* = N0 + ln2 / (2 eps). A sampler with wrong
  // acceptance factors or broken bookkeeping lands somewhere else.
  for (const eps of [0.002, 0.004]) {
    const c = new CDT(20, 20, 9, 800, eps); for (let k = 0; k < 400; k++) c.sweep();
    const Ns = []; for (let k = 0; k < 1500; k++) { c.sweep(); Ns.push(c.N); }
    const m = mean(Ns), B = 15, bs = Ns.length / B, bm = []; for (let b = 0; b < B; b++) bm.push(mean(Ns.slice(b * bs, (b + 1) * bs)));
    const err = Math.sqrt(bm.reduce((s, x) => s + (x - m) ** 2, 0) / (B * (B - 1))), lam = 2 * eps * (m - 800);
    ok(`CDT entropy per triangle (eps ${eps})`, Math.abs(lam - Math.LN2) < 0.06, `<N> = ${m.toFixed(1)} ± ${err.toFixed(1)} -> lambda_c = 2 eps (<N> - N0) = ${lam.toFixed(3)} ± ${(2 * eps * err).toFixed(3)}; exact ln 2 = 0.693`);
  }
  console.log(fail ? `${fail} check(s) failed` : "all checks passed"); process.exitCode = fail ? 1 : 0;
}
if (mode === "dims") {
  const R = rng(17);
  const report = (name, sizes, make, therm, meas, gap) => {
    const rows = [];
    for (const N of sizes) {
      const m = make(N); for (let k = 0; k < therm; k++) m.sweep();
      const rs = [], sh = new Array(16).fill(0); let nsh = 0;
      for (let q = 0; q < meas; q++) { for (let k = 0; k < gap; k++) m.sweep(); const g = m.graph(); rs.push(meanDistance(g, R, 10));
        for (let s = 0; s < 20; s++) { const o = shells(g, (R() * g.length) | 0, 15); o.forEach((v, r) => sh[r] += v); nsh++; } }
      const V = m.graph().length; rows.push({ N, V, r: mean(rs), shells: sh.map(v => v / nsh) });
      console.log(`${name} N ${N} (vertices ${V}): mean distance ${mean(rs).toFixed(3)}; shell sizes r=1..10: ${sh.slice(1, 11).map(v => (v / nsh).toFixed(1)).join(" ")}`);
    }
    const dH = 1 / fitSlope(rows.map(x => Math.log(x.V)), rows.map(x => Math.log(x.r)));
    const big = rows[rows.length - 1].shells, rr = [3, 4, 5, 6, 7, 8], sl = fitSlope(rr.map(Math.log), rr.map(r => Math.log(big[r])));
    console.log(`${name}: size scaling <r> ~ V^(1/dH) -> dH = ${dH.toFixed(2)};  ball growth n(r) ~ r^(dH-1) for r 3-8 at the largest size -> dH = ${(sl + 1).toFixed(2)}`);
    return { dH, dHshell: sl + 1, rows };
  };
  const therm = +(process.argv[3] ?? 2000), meas = +(process.argv[4] ?? 40), gap = +(process.argv[5] ?? 50);
  const dt = report("DT ", [1000, 2000, 4000, 8000, 16000], N => new DT(N, 5), therm, meas, gap);
  // CDT: keep the shape fixed as it grows (T ~ sqrt(N/2)), so the size scaling isn't distorted by a changing aspect ratio
  const cdt = report("CDT", [1000, 2000, 4000, 8000, 16000], N => { const T = Math.round(Math.sqrt(N / 2)); return new CDT(T, Math.round(N / (2 * T)), 7, N, 4 / N); }, therm, meas, gap);
  console.log(JSON.stringify({ dt: { dH: dt.dH, dHshell: dt.dHshell }, cdt: { dH: cdt.dH, dHshell: cdt.dHshell } }));
}
