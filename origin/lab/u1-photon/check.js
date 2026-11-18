// Checks for u1.js. node check.js  (about 30 s)
// 1. 2D is solved exactly: <cos theta_p> = I1(beta)/I0(beta), and W(R,T) = (I1/I0)^(R T).
// 2. Gauge invariance: shifting every site by a random phase leaves plaquettes, loops, smeared loops unchanged.
// 3. 4D strong coupling <cos theta_p> ~ beta/2, weak coupling 1 - 1/(4 beta).
const { U1, besselI } = require("./u1.js");
let fail = 0; const ok = (n, c, d) => { console.log(`${c ? "PASS" : "FAIL"}  ${n}  ${d}`); if (!c) fail++; };
const run = (prm, therm, meas, f) => { const L = new U1(prm); for (let s = 0; s < therm; s++) L.sweep(); const v = []; for (let k = 0; k < meas; k++) { L.sweep(); v.push(f(L)); }
  const m = v.reduce((a, b) => a + b, 0) / v.length; // error from 10 blocks, to allow for autocorrelation
  const B = 10, bs = v.length / B, bm = []; for (let b = 0; b < B; b++) bm.push(v.slice(b * bs, (b + 1) * bs).reduce((a, x) => a + x, 0) / bs);
  return [m, Math.sqrt(bm.reduce((s, x) => s + (x - m) ** 2, 0) / (B * (B - 1)))]; };
for (const b of [0.5, 1, 2, 4]) {
  const [m, e] = run({ d: 2, L: 32, beta: b, delta: 2, seed: 3 }, 300, 400, L => L.plaquette()), ex = besselI(1, b) / besselI(0, b);
  ok(`2D plaquette beta ${b}`, Math.abs(m - ex) < 4 * e + 2e-4, `${m.toFixed(5)} ± ${e.toFixed(5)} vs exact ${ex.toFixed(5)}`);
}
{
  const b = 2, ex = besselI(1, b) / besselI(0, b), L = new U1({ d: 2, L: 32, beta: b, delta: 2, seed: 7 }); for (let s = 0; s < 300; s++) L.sweep();
  const acc = {}; const n = 400; for (let k = 0; k < n; k++) { L.sweep(); const W = L.loops(3, 3, 1); for (const q in W) acc[q] = (acc[q] || 0) + W[q] / n; }
  let worst = 0, txt = []; for (const [R, T] of [[1, 1], [2, 1], [2, 2], [3, 2]]) { const w = acc[R + "," + T], e = ex ** (R * T); worst = Math.max(worst, Math.abs(Math.log(w / e)) / (R * T)); txt.push(`W(${R},${T}) ${w.toFixed(4)}/${e.toFixed(4)}`); }
  ok("2D Wilson loops = (I1/I0)^area", worst < 0.02, txt.join("  "));
}
{
  const L = new U1({ d: 4, L: 4, beta: 1.0, start: "hot", seed: 2 }); for (let s = 0; s < 10; s++) L.sweep();
  const f = () => [L.plaquette(), L.loops(2, 2, 3)["2,2"], L.loops(2, 2, 3, L.ape([0, 1, 2], 0.5, 3))["2,2"]], a = f();
  const g = Array.from({ length: L.V }, () => (2 * Math.random() - 1) * Math.PI), d = 4;
  for (let i = 0; i < L.V; i++) for (let mu = 0; mu < d; mu++) L.th[i * d + mu] += g[i] - g[L.up[i * d + mu]];
  const b = f(), diff = Math.max(...a.map((x, k) => Math.abs(x - b[k])));
  ok("gauge invariance", diff < 1e-12, `plaquette, W(2,2), smeared W(2,2): largest change ${diff.toExponential(2)}`);
}
for (const [b, ref, name] of [[0.1, 0.05, "strong"], [0.2, 0.1, "strong"], [8, 1 - 1 / 32, "weak"], [16, 1 - 1 / 64, "weak"]]) {
  const [m, e] = run({ d: 4, L: 4, beta: b, delta: b > 2 ? 0.5 : 3, seed: 5 }, 100, 200, L => L.plaquette());
  ok(`4D ${name} coupling beta ${b}`, Math.abs(m - ref) < 0.006 + 4 * e, `${m.toFixed(4)} ± ${e.toFixed(4)} vs leading order ${ref.toFixed(4)}`);
}
console.log(fail ? `${fail} check(s) failed` : "all checks passed"); process.exitCode = fail ? 1 : 0;
