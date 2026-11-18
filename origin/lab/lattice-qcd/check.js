// Checks for su3.js. node check.js  (about a minute)
// 1. Links stay in SU(3) after many updates.
// 2. Gauge invariance: a random SU(3) rotation at every site leaves every plaquette, Wilson loop and
//    |Polyakov loop| unchanged (the core symmetry of QCD; a wrong link or orientation breaks it).
// 3. Strong and weak coupling: the plaquette matches the leading expansions beta/18 + beta^2/216
//    (small beta) and 1 - 2/beta (large beta).
// 4. Cold and hot starts reach the same plaquette.
const { Lattice, strongCoupling, weakCoupling, _m } = require("./su3.js");
const { mul, mulDag, dagMul, M3, setId } = _m;
let fail = 0; const ok = (name, cond, detail) => { console.log(`${cond ? "PASS" : "FAIL"}  ${name}  ${detail}`); if (!cond) fail++; };

// 1 + 2
{
  const L = new Lattice({ Ns: 4, Nt: 4, beta: 5.7, start: "hot", seed: 3 });
  for (let s = 0; s < 20; s++) L.sweep();
  ok("unitarity", L.unitarityError() < 1e-12, `max |U U^dag - 1| = ${L.unitarityError().toExponential(2)}`);
  const before = { p: L.plaquette(), w: L.wilson(2, 2), ws: L.wilsonSpatial(1, 2), pl: Math.hypot(...L.polyakov()) };
  // random gauge transform g(x): U_mu(x) -> g(x) U_mu(x) g(x+mu)^dag
  const R = Math.random, g = [];
  for (let i = 0; i < L.V; i++) { const u = M3(); for (let k = 0; k < 18; k++) u[k] = R() - 0.5; _m.reunitarize(u); g.push(u); }
  const t = M3();
  for (let i = 0; i < L.V; i++) for (let mu = 0; mu < 4; mu++) { const u = L.link(i, mu); mul(g[i], u, t); mulDag(t, g[L.up[i * 4 + mu]], u); }
  const after = { p: L.plaquette(), w: L.wilson(2, 2), ws: L.wilsonSpatial(1, 2), pl: Math.hypot(...L.polyakov()) };
  const d = Math.max(...Object.keys(before).map(k => Math.abs(before[k] - after[k])));
  ok("gauge invariance", d < 1e-12, `largest change in plaquette, W(2,2), spatial W(1,2), |Polyakov| = ${d.toExponential(2)}`);
}
// 3
for (const [beta, ref, tol, name] of [[0.5, strongCoupling(0.5), 0.004, "strong coupling"], [1.0, strongCoupling(1.0), 0.006, "strong coupling"], [30, weakCoupling(30), 0.006, "weak coupling"], [60, weakCoupling(60), 0.003, "weak coupling"]]) {
  const L = new Lattice({ Ns: 4, Nt: 4, beta, start: "cold", seed: 5, eps: beta > 10 ? 0.06 : 0.6 });
  for (let s = 0; s < 40; s++) L.sweep();
  let s = 0; const n = 20; for (let k = 0; k < n; k++) { L.sweep(); s += L.plaquette(); }
  const p = s / n;
  ok(`${name} beta ${beta}`, Math.abs(p - ref) < tol, `plaquette ${p.toFixed(4)} vs expansion ${ref.toFixed(4)} (acceptance ${L.acceptance().toFixed(2)})`);
}
// 4
{
  const res = [];
  for (const start of ["cold", "hot"]) {
    const L = new Lattice({ Ns: 4, Nt: 4, beta: 5.5, start, seed: 9 });
    for (let s = 0; s < 400; s++) L.sweep();
    let s = 0; for (let k = 0; k < 100; k++) { L.sweep(); s += L.plaquette(); } res.push(s / 100);
  }
  ok("cold and hot starts agree", Math.abs(res[0] - res[1]) < 0.01, `beta 5.5: cold ${res[0].toFixed(4)}, hot ${res[1].toFixed(4)}`);
}
console.log(fail ? `${fail} check(s) failed` : "all checks passed");
process.exitCode = fail ? 1 : 0;
